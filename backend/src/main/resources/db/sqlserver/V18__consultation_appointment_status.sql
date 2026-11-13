-- Atomic consultation + optional appointment outcome; historical consultations remain immutable.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1 THROW 51000,'HP_INVALID:Separate transactional migration principal required',1;
IF OBJECT_ID(N'dbo.medical_services') IS NULL OR COL_LENGTH(N'dbo.medical_consultations',N'appointment_id') IS NOT NULL THROW 51003,'HP_CONFLICT:V17 required; V18 cannot be reapplied',1;
ALTER TABLE dbo.medical_consultations ADD appointment_id char(36) COLLATE Latin1_General_100_BIN2 NULL;
ALTER TABLE dbo.appointments DROP CONSTRAINT CK_appointments_status_enum;
ALTER TABLE dbo.appointments WITH CHECK ADD CONSTRAINT CK_appointments_status_enum CHECK(status IN ('REQUESTED','RESERVED','CONFIRMED','WAITING','CALLED','IN_CARE','COMPLETED','CANCELLED','WITHDRAWN','NO_SHOW'));
GO
ALTER TABLE dbo.medical_consultations WITH CHECK ADD CONSTRAINT FK_consultation_appointment FOREIGN KEY(tenant_id,appointment_id) REFERENCES dbo.appointments(tenant_id,id);
GO

ALTER PROCEDURE dbo.usp_consultation_add @id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'PRO',@write=1;EXEC dbo.usp_require_transaction;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id'));
 IF ISJSON(@input,OBJECT)<>1 THROW 51000,'HP_INVALID:Consultation object required',1;
 IF (SELECT COUNT(*) FROM OPENJSON(@input))<>10 OR EXISTS(SELECT [key] FROM OPENJSON(@input) GROUP BY [key] HAVING COUNT(*)<>1)
 OR EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE ([key] NOT IN ('appointmentId','expectedAppointmentRevision') AND [type]<>1) OR ([key]='appointmentId' AND [type] NOT IN (0,1)) OR ([key]='expectedAppointmentRevision' AND [type] NOT IN (0,2)) OR [key] NOT IN ('requestId','patientId','branchId','anamnesis','physicalExam','diagnosis','treatment','status','appointmentId','expectedAppointmentRevision') OR DATALENGTH(value)>40000)
 THROW 51000,'HP_INVALID:Invalid consultation fields',1;
 DECLARE @patient char(36)=JSON_VALUE(@input,'$.patientId'),@branch char(36)=JSON_VALUE(@input,'$.branchId'),@state varchar(9)=JSON_VALUE(@input,'$.status'),@hash char(64)=CONVERT(char(64),HASHBYTES('SHA2_256',@input),2);
 IF JSON_VALUE(@input,'$.requestId')<>@id OR DATALENGTH(JSON_VALUE(@input,'$.patientId'))<>72 OR DATALENGTH(JSON_VALUE(@input,'$.branchId'))<>72
 OR JSON_VALUE(@input,'$.status') COLLATE Latin1_General_100_BIN2 NOT IN ('ATTENDED','PENDING','CANCELLED','NO_SHOW')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [key]='anamnesis' AND NULLIF(LTRIM(RTRIM(value)),N'') IS NOT NULL) THROW 51000,'HP_INVALID:Invalid consultation identity or content',1;
 EXEC dbo.usp_clinical_branch_guard @branch;
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient)THROW 51002,'HP_NOT_FOUND:Patient not found',1;
 IF EXISTS(SELECT 1 FROM dbo.medical_consultations WITH(UPDLOCK,HOLDLOCK) WHERE id=@id)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.medical_consultations WHERE id=@id AND tenant_id=@t AND professional_id=@u AND request_hash=@hash)THROW 51003,'HP_CONFLICT:Request already used with different content',1;
 END
 ELSE BEGIN
  DECLARE @appointment char(36)=JSON_VALUE(@input,'$.appointmentId'),@expected_ap int=TRY_CONVERT(int,JSON_VALUE(@input,'$.expectedAppointmentRevision')),@old nvarchar(9),@ap_revision int,@locked char(36),@next nvarchar(9);
  IF (@appointment IS NULL AND @expected_ap IS NOT NULL) OR (@appointment IS NOT NULL AND (@expected_ap IS NULL OR @expected_ap<1 OR DATALENGTH(JSON_VALUE(@input,'$.appointmentId'))<>72)) THROW 51000,'HP_INVALID:Appointment and revision required together',1;
  IF @appointment IS NOT NULL
  BEGIN
   SELECT @locked=id FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@u;
   SELECT @old=status,@ap_revision=revision FROM dbo.appointments WITH(UPDLOCK,HOLDLOCK) WHERE id=@appointment AND tenant_id=@t AND patient_id=@patient AND branch_id=@branch AND professional_id=@u;
   IF @old IS NULL THROW 51002,'HP_NOT_FOUND:Appointment not available for this patient, branch and professional',1;
   IF @ap_revision<>@expected_ap OR @ap_revision=2147483647 THROW 51003,'HP_CONFLICT:Appointment changed; reload',1;
   SET @next=CASE @state WHEN 'ATTENDED' THEN 'COMPLETED' WHEN 'CANCELLED' THEN 'CANCELLED' WHEN 'NO_SHOW' THEN 'NO_SHOW' ELSE @old END;
   IF @next<>@old AND NOT ((@next='COMPLETED' AND @old IN ('RESERVED','CONFIRMED','WAITING','CALLED','IN_CARE')) OR (@next IN ('CANCELLED','NO_SHOW') AND @old IN ('REQUESTED','RESERVED','CONFIRMED','WAITING','CALLED'))) THROW 51003,'HP_CONFLICT:Appointment is closed or transition is not allowed',1;
   IF @next<>@old BEGIN
    UPDATE dbo.appointments SET status=@next,revision=revision+1 WHERE tenant_id=@t AND id=@appointment AND revision=@expected_ap;
    EXEC dbo.usp_audit_event @t,N'APPOINTMENT_CLINICAL_STATUS',@appointment;
   END;
  END;
  INSERT dbo.medical_consultations(id,tenant_id,patient_id,branch_id,professional_id,anamnesis,physical_exam,diagnosis,treatment,status,request_hash,appointment_id)
  SELECT @id,@t,@patient,@branch,@u,j.anamnesis,j.physicalExam,j.diagnosis,j.treatment,@state,@hash,@appointment FROM OPENJSON(@input) WITH(anamnesis nvarchar(max),physicalExam nvarchar(max),diagnosis nvarchar(max),treatment nvarchar(max)) j;
  EXEC dbo.usp_audit_event @t,N'CONSULTATION_ADDED',@id;
 END;
 SELECT c.id,c.appointment_id,c.patient_id,c.branch_id,b.name branch_name,c.professional_id,u.name professional_name,c.anamnesis,c.physical_exam,c.diagnosis,c.treatment,c.status,c.created_at
 FROM dbo.medical_consultations c JOIN dbo.users u ON u.id=c.professional_id JOIN dbo.branches b ON b.tenant_id=c.tenant_id AND b.id=c.branch_id WHERE c.id=@id AND c.tenant_id=@t;
END;

GO

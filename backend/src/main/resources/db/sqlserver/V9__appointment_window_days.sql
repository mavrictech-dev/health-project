-- SQL-01.A36.R1 / R-A36-SQL-WINDOW. Incremental, no runtime activation.
-- Preserve V5 exactly except BIGINT divisor: complete elapsed days, not decimal days.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE dbo.usp_appointments_list @from datetime2(6),@to datetime2(6),@branch_id char(36)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'REC,PRO,ASI,AUD'; IF @from IS NULL OR @to IS NULL OR @to<=@from OR DATEDIFF_BIG(microsecond,@from,@to)/CONVERT(bigint,86400000000)>93 THROW 51000,'HP_INVALID:Consulta como maximo 93 dias UTC',1; IF @branch_id IS NOT NULL EXEC dbo.usp_clinical_branch_guard @branch_id; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); SELECT TOP(200) id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,revision,request_key,request_hash FROM dbo.appointments WHERE tenant_id=@t AND starts_at>=@from AND starts_at<@to AND (@branch_id IS NULL OR branch_id=@branch_id) ORDER BY starts_at,id;
END;
GO

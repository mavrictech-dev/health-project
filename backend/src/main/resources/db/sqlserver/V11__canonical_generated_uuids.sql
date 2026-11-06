-- Preserve canonical lowercase UUIDs required by HTTP/store contracts.
-- SQL Server NEWID -> char emits uppercase; Java-created UUIDs are lowercase.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE dbo.usp_saas_tenant_create @tenant_id char(36),@branch_id char(36),@owner_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_saas_write_gate;
 DECLARE @public bit=CASE WHEN CONVERT(varchar(20),SESSION_CONTEXT(N'hp_scope'))='IDENTITY' AND SESSION_CONTEXT(N'hp_actor_id') IS NULL AND SESSION_CONTEXT(N'hp_tenant_id') IS NULL THEN 1 ELSE 0 END;
 IF @public=0 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1;
 EXEC dbo.usp_org_json_object @input,N'{"name":1,"slug":1,"kind":1,"domain":1,"timezone":1,"branchName":1,"address":1,"specialties":4,"subscription":5}';
 DECLARE @name nvarchar(max),@slug nvarchar(max),@kind nvarchar(max),@domain nvarchar(max),@zone nvarchar(max),@bname nvarchar(max),@address nvarchar(max),@codes nvarchar(max),@sub nvarchar(max),@pid char(36),@ver int,@cycle nvarchar(7),@b int,@pr int,@sc int,@modules nvarchar(max),@owner_domain nvarchar(6),@verified bit,@user_exists char(36);
 SELECT @name=name,@slug=slug,@kind=kind,@domain=domain,@zone=timezone,@bname=branchName,@address=address,@codes=specialties,@sub=subscription FROM OPENJSON(@input) WITH(name nvarchar(max),slug nvarchar(max),kind nvarchar(max),domain nvarchar(max),timezone nvarchar(max),branchName nvarchar(max),address nvarchar(max),specialties nvarchar(max) AS JSON,subscription nvarchar(max) AS JSON);
 IF @tenant_id IS NULL OR @branch_id IS NULL OR @owner_id IS NULL OR NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR DATALENGTH(@name)>320 OR NULLIF(LTRIM(RTRIM(@bname)),N'') IS NULL OR DATALENGTH(@bname)>320 OR DATALENGTH(@address)>600 OR NULLIF(LTRIM(RTRIM(@zone)),N'') IS NULL OR DATALENGTH(@zone)>128 OR DATALENGTH(@kind)<>2*LEN(@kind) OR DATALENGTH(@domain)<>2*LEN(@domain) OR @kind COLLATE Latin1_General_100_BIN2 NOT IN ('DOCTOR','CLINIC','HOSPITAL','VETERINARY','DENTAL','SPECIALTY_CENTER') OR @domain COLLATE Latin1_General_100_BIN2 NOT IN ('HUMAN','ANIMAL') OR (@kind='VETERINARY' AND @domain<>'ANIMAL') OR (@kind NOT IN ('DOCTOR','VETERINARY') AND @domain<>'HUMAN') THROW 51000,'HP_INVALID:Datos de organizacion invalidos',1;
 IF LEN(@slug) NOT BETWEEN 1 AND 63 OR DATALENGTH(@slug)<>2*LEN(@slug) OR @slug COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-z0-9-]%' OR LEFT(@slug,1)='-' OR RIGHT(@slug,1)='-' OR @slug LIKE N'%--%' OR @slug IN ('www','admin','api','app','saas','mail','support','status','auth','portal','localhost') THROW 51000,'HP_INVALID:Subdominio invalido o reservado',1;
 SELECT @user_exists=id,@owner_domain=clinical_domain,@verified=email_verified FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@owner_id AND active=1 AND platform_role IS NULL;
 IF @user_exists IS NULL OR (@kind='DOCTOR' AND (@owner_domain IS NULL OR @owner_domain<>@domain)) THROW 51000,'HP_INVALID:Propietario o dominio incompatible',1;
 IF @public=1 AND (@verified<>0 OR EXISTS(SELECT 1 FROM dbo.memberships WITH(UPDLOCK,HOLDLOCK) WHERE user_id=@owner_id) OR EXISTS(SELECT 1 FROM dbo.tenants WITH(UPDLOCK,HOLDLOCK) WHERE owner_user_id=@owner_id)) THROW 51001,'HP_FORBIDDEN:El registro requiere identidad nueva sin membresias',1;
 IF EXISTS(SELECT 1 FROM dbo.branches WITH(UPDLOCK,HOLDLOCK) WHERE id=@branch_id) THROW 51003,'HP_CONFLICT:Identificador de sede existente',1; IF EXISTS(SELECT 1 FROM dbo.tenants WITH(UPDLOCK,HOLDLOCK) WHERE slug=@slug OR id=@tenant_id) THROW 51003,'HP_CONFLICT:Subdominio o cliente existente',1;
 EXEC dbo.usp_org_subscription_resolve @sub,@kind,@domain,@public,@pid OUTPUT,@ver OUTPUT,@cycle OUTPUT,@b OUTPUT,@pr OUTPUT,@sc OUTPUT,@modules OUTPUT;
 EXEC dbo.usp_org_validate_specialties @codes,@domain,@kind,@sc,@modules;
 INSERT dbo.tenants(id,name,slug,kind,domain,owner_user_id,timezone) VALUES(@tenant_id,@name,@slug,@kind,@domain,@owner_id,@zone);
 INSERT dbo.subscriptions(tenant_id,plan_id,plan_version,cycle,branch_quota,professional_quota,specialty_quota,renewal_date) VALUES(@tenant_id,@pid,@ver,@cycle,@b,@pr,@sc,CONVERT(date,CASE WHEN @cycle='YEARLY' THEN DATEADD(year,1,SYSUTCDATETIME()) ELSE DATEADD(month,1,SYSUTCDATETIME()) END));
 INSERT dbo.branches(id,tenant_id,name,address,[external],active) VALUES(@branch_id,@tenant_id,@bname,@address,0,1);
 INSERT dbo.tenant_specialties(tenant_id,specialty_code) SELECT @tenant_id,value FROM OPENJSON(@codes);
 INSERT dbo.areas(id,tenant_id,branch_id,name,specialties) VALUES(LOWER(CONVERT(char(36),NEWID())),@tenant_id,@branch_id,N'Consulta y atencion',@codes);
 INSERT dbo.memberships(tenant_id,user_id,roles,status,owner) VALUES(@tenant_id,@owner_id,CASE WHEN @kind='DOCTOR' THEN N'["ADM","PRO"]' ELSE N'["ADM"]' END,'ACTIVE',1);
 INSERT dbo.membership_branches(tenant_id,user_id,branch_id) VALUES(@tenant_id,@owner_id,@branch_id);
 IF @kind='DOCTOR' INSERT dbo.membership_specialties(tenant_id,user_id,specialty_code) SELECT @tenant_id,@owner_id,value FROM OPENJSON(@codes);
 DECLARE @meta nvarchar(max)=(SELECT @slug slug FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @tenant_id,N'TENANT_CREATED',@tenant_id,@meta;
 IF @public=0 EXEC dbo.usp_platform_tenants @tenant_id; ELSE SELECT @tenant_id id,@tenant_id tenant_id,@slug slug,@kind kind,@domain domain,CAST('TRIAL' AS nvarchar(10)) status;
END;
GO
ALTER PROCEDURE dbo.usp_inventory_transfer_receive @transfer_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'ALM',N'INVENTORY',@write=1;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@state nvarchar(10),@source char(36),@dest char(36),@qty decimal(14,3),@name nvarchar(160),@lot nvarchar(100),@unit nvarchar(30),@expiry date,@target char(36),@targetunit nvarchar(30),@stock decimal(14,3);
 SELECT @state=status,@source=lot_id,@dest=destination_branch_id,@qty=quantity FROM dbo.stock_transfers WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@transfer_id;
 IF @state IS NULL THROW 51002,'HP_NOT_FOUND:Transferencia inexistente',1;
 EXEC dbo.usp_operations_branch @dest;
 IF @state='IN_TRANSIT' BEGIN SELECT @name=name,@lot=lot,@unit=unit,@expiry=expiry FROM dbo.stock_lots WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@source;
 IF @name IS NULL THROW 51002,'HP_NOT_FOUND:Lote de origen inexistente',1;
 SELECT @target=id,@targetunit=unit,@stock=quantity FROM dbo.stock_lots WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND branch_id=@dest AND name=@name AND lot=@lot AND expiry=@expiry;
 IF @target IS NOT NULL BEGIN IF @targetunit COLLATE Latin1_General_100_BIN2<>@unit COLLATE Latin1_General_100_BIN2 OR DATALENGTH(@targetunit)<>DATALENGTH(@unit) THROW 51003,'HP_CONFLICT:Unidad del lote de destino incompatible',1;
 IF CONVERT(decimal(38,0),@stock*1000)+CONVERT(decimal(38,0),@qty*1000)>CONVERT(decimal(38,0),99999999999999) THROW 51003,'HP_CONFLICT:Stock destino fuera de rango',1;
 UPDATE dbo.stock_lots SET quantity=quantity+@qty WHERE tenant_id=@t AND id=@target;
 END ELSE INSERT dbo.stock_lots(id,tenant_id,branch_id,name,lot,expiry,quantity,unit) VALUES(LOWER(CONVERT(char(36),NEWID())),@t,@dest,@name,@lot,@expiry,@qty,@unit);
 UPDATE dbo.stock_transfers SET status='RECEIVED',received_at=SYSUTCDATETIME() WHERE tenant_id=@t AND id=@transfer_id;
 EXEC dbo.usp_audit_event @t,N'TRANSFER_RECEIVED',@transfer_id;
 END;
 SELECT id,tenant_id,lot_id,destination_branch_id,quantity,status,request_key,request_hash,created_at,received_at FROM dbo.stock_transfers WHERE tenant_id=@t AND id=@transfer_id;
END;
GO
-- Areas have no referencing foreign keys in this schema. Preserve all data and
-- audit the key correction; refuse unexpected future dependencies/collisions.
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE referenced_object_id=OBJECT_ID(N'dbo.areas')) THROW 59999,'Area UUID remediation requires dependency review',1;
IF EXISTS(SELECT LOWER(id) FROM dbo.areas GROUP BY LOWER(id) HAVING COUNT(*)>1) THROW 59999,'Area UUID canonical collision',1;
UPDATE dbo.areas SET id=LOWER(id) WHERE id COLLATE Latin1_General_100_BIN2<>LOWER(id) COLLATE Latin1_General_100_BIN2;
GO

-- SQL Server 2022 operations persistence. Dependencies ONLY dbo tables + accepted V3/V4 helpers.
-- No V5 dependency; no provider/payment/SMTP side effects. Caller owns the Spring transaction.
-- Private operations_* helpers must not receive runtime EXECUTE grants.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- PRIVATE Access.roles/module/write replacement. Never grants platform access to clinical/patient finance data.
CREATE PROCEDURE dbo.usp_operations_scope @roles nvarchar(200),@module nvarchar(40),@write bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Se requiere sesion tenant',1;
 IF @write=1 EXEC dbo.usp_write_guard @t,@module;
 ELSE IF NOT EXISTS(SELECT 1 FROM dbo.subscriptions s JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version CROSS APPLY OPENJSON(v.modules) j WHERE s.tenant_id=@t AND j.value COLLATE Latin1_General_100_BIN2=@module COLLATE Latin1_General_100_BIN2) THROW 51001,'HP_FORBIDDEN:Modulo no incluido',1;
END;
GO

-- PRIVATE current tenant active branch assignment via accepted V3; no V5 dependency.
CREATE PROCEDURE dbo.usp_operations_branch @branch_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @allowed TABLE(id char(36),branch_id char(36)); INSERT @allowed EXEC dbo.usp_access_branch @branch_id; IF NOT EXISTS(SELECT 1 FROM @allowed) THROW 51001,'HP_FORBIDDEN:Sede no disponible para esta membresia',1;
END;
GO

-- PRIVATE strict JSON DTO types with nullable fields; no client SQL text.
CREATE PROCEDURE dbo.usp_operations_json @input nvarchar(max),@contract nvarchar(max),@nullable nvarchar(max)=N'[]'
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @input IS NULL OR ISJSON(@input,OBJECT)<>1 THROW 51000,'HP_INVALID:Objeto JSON requerido',1;
 IF EXISTS(SELECT [key] FROM OPENJSON(@input) GROUP BY [key] HAVING COUNT(*)>1) OR EXISTS(SELECT 1 FROM OPENJSON(@input) i LEFT JOIN OPENJSON(@contract) c ON c.[key]=i.[key] WHERE c.[key] IS NULL OR (i.type<>TRY_CONVERT(int,c.value) AND NOT(i.type=0 AND EXISTS(SELECT 1 FROM OPENJSON(@nullable) n WHERE n.value COLLATE Latin1_General_100_BIN2=i.[key])))) OR EXISTS(SELECT 1 FROM OPENJSON(@contract) c WHERE NOT EXISTS(SELECT 1 FROM OPENJSON(@input) i WHERE i.[key]=c.[key])) THROW 51000,'HP_INVALID:Campos ausentes, repetidos o de tipo incorrecto',1;
END;
GO

-- PRIVATE server Checks.hash + Idempotency.key contract. Stored hash only, never raw credentials.
CREATE PROCEDURE dbo.usp_operations_idempotency @request_key nvarchar(max),@request_hash char(64)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @request_key IS NULL OR LEN(@request_key) NOT BETWEEN 8 AND 100 OR DATALENGTH(@request_key)<>2*LEN(@request_key) OR @request_key COLLATE Latin1_General_100_BIN2 LIKE N'%[^-A-Za-z0-9_.:]%' OR @request_hash IS NULL OR LEN(@request_hash)<>64 OR @request_hash COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9a-f]%' THROW 51000,'HP_INVALID:Clave o hash de idempotencia invalido',1;
END;
GO

-- PRIVATE exact decimal parser for JSON BigDecimal, including exponent notation; rejects precision loss instead of rounding through FLOAT or DECIMAL casts.
CREATE PROCEDURE dbo.usp_operations_quantity @text nvarchar(max),@quantity decimal(14,3) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @text IS NULL OR LEN(@text)>100 OR @text COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9.eE+-]%' THROW 51000,'HP_INVALID:Cantidad decimal invalida',1;
 DECLARE @e int=0,@pos int=CHARINDEX('e',LOWER(@text)),@mantissa nvarchar(100),@dot int,@scale int,@digits nvarchar(200),@normalized nvarchar(220);
 IF @pos>0 BEGIN SET @e=TRY_CONVERT(int,SUBSTRING(@text,@pos+1,100)); SET @mantissa=LEFT(@text,@pos-1); END ELSE SET @mantissa=@text;
 IF @e IS NULL OR @e NOT BETWEEN -100 AND 100 OR LEFT(@mantissa,1)='-' THROW 51000,'HP_INVALID:Cantidad positiva requerida',1;
 SET @dot=CHARINDEX('.',@mantissa); SET @scale=CASE WHEN @dot=0 THEN 0 ELSE LEN(@mantissa)-@dot END-@e; SET @digits=REPLACE(@mantissa,'.','');
 IF @digits=N'' OR @digits COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9]%' OR CHARINDEX('.',@mantissa,@dot+1)>0 THROW 51000,'HP_INVALID:Cantidad decimal invalida',1;
 WHILE LEN(@digits)>1 AND LEFT(@digits,1)='0' SET @digits=SUBSTRING(@digits,2,200);
 WHILE @scale>0 AND RIGHT(@digits,1)='0' AND LEN(@digits)>0 BEGIN SET @digits=LEFT(@digits,LEN(@digits)-1); SET @scale=@scale-1; END;
 IF @scale<0 BEGIN IF LEN(@digits)-@scale>11 THROW 51000,'HP_INVALID:Cantidad fuera de rango',1; SET @digits=@digits+REPLICATE(N'0',-@scale); SET @scale=0; END;
 IF @scale>3 OR LEN(@digits)-@scale>11 OR @digits=N'' THROW 51000,'HP_INVALID:Cantidad requiere hasta once enteros y tres decimales',1;
 IF @scale=0 SET @normalized=@digits; ELSE BEGIN WHILE LEN(@digits)<=@scale SET @digits=N'0'+@digits; SET @normalized=LEFT(@digits,LEN(@digits)-@scale)+N'.'+RIGHT(@digits,@scale); END;
 SET @quantity=TRY_CONVERT(decimal(14,3),@normalized); IF @quantity IS NULL OR @quantity<0.001 THROW 51000,'HP_INVALID:Cantidad positiva requerida',1;
END;
GO

-- FinanceService.balance: CAJ/AUD, no PRO permission dependency. Exact decimal38 aggregate avoids BIGINT SUM overflow; Java Number/monetary serialization unchanged.
CREATE PROCEDURE dbo.usp_finance_balance @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'CAJ,AUD',N'FINANCE';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1;
 SELECT COALESCE(SUM(CASE WHEN kind='PAYMENT' THEN -CONVERT(decimal(38,0),amount_minor) ELSE CONVERT(decimal(38,0),amount_minor) END),CONVERT(decimal(38,0),0)) balance_minor,CAST('PEN' AS char(3)) currency FROM dbo.finance_movements WHERE tenant_id=@t AND patient_id=@patient_id;
END;
GO

-- FinanceService.movements: patient existence directly, not a clinical patient_get call; existing 200-row projection.
CREATE PROCEDURE dbo.usp_finance_movements @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'CAJ,AUD',N'FINANCE';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1;
 SELECT TOP(200) id,tenant_id,patient_id,kind,amount_minor,currency,title,parent_id,actor_id,request_key,request_hash,created_at FROM dbo.finance_movements WHERE tenant_id=@t AND patient_id=@patient_id ORDER BY created_at DESC,id;
END;
GO

-- FinanceService.post / historical V4: patient + refund parent locks; existing same-key/hash returns row without new effects; no SaaS invoice or external charge.
CREATE PROCEDURE dbo.usp_finance_post @movement_id char(36),@input nvarchar(max),@request_key nvarchar(max),@request_hash char(64)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'CAJ',N'FINANCE',@write=1;
 EXEC dbo.usp_operations_idempotency @request_key,@request_hash;
 EXEC dbo.usp_operations_json @input,N'{"patientId":1,"kind":1,"amountMinor":2,"title":1,"parentId":1}',N'["parentId"]';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@patient nvarchar(max),@kind nvarchar(max),@title nvarchar(max),@parent nvarchar(max),@raw nvarchar(max),@amount bigint,@pid char(36),@existing char(36),@hash char(64),@balance decimal(38,0),@paid bigint,@refunded decimal(38,0);
 SELECT @patient=patientId,@kind=kind,@title=title,@parent=parentId,@raw=amountMinor FROM OPENJSON(@input) WITH(patientId nvarchar(max),kind nvarchar(max),title nvarchar(max),parentId nvarchar(max),amountMinor nvarchar(max));
 SET @amount=TRY_CONVERT(bigint,@raw);
 IF @movement_id IS NULL OR DATALENGTH(@patient)<>72 OR TRY_CONVERT(uniqueidentifier,@patient) IS NULL OR @kind COLLATE Latin1_General_100_BIN2 NOT IN ('CHARGE','PAYMENT','REFUND') OR DATALENGTH(@kind)<>2*LEN(@kind) OR @amount IS NULL OR @amount NOT BETWEEN 1 AND 1000000000000 OR NULLIF(LTRIM(RTRIM(@title)),N'') IS NULL OR DATALENGTH(@title)>400 OR (@parent IS NOT NULL AND (DATALENGTH(@parent)<>72 OR TRY_CONVERT(uniqueidentifier,@parent) IS NULL)) THROW 51000,'HP_INVALID:Movimiento financiero invalido',1;
 SELECT @pid=id FROM dbo.patients WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@patient;
 IF @pid IS NULL THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1;
 SELECT @existing=id,@hash=request_hash FROM dbo.finance_movements WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND request_key=@request_key;
 IF @existing IS NOT NULL BEGIN IF @hash<>@request_hash THROW 51003,'HP_CONFLICT:Clave utilizada con otros datos',1;
 SELECT id,tenant_id,patient_id,kind,amount_minor,currency,title,parent_id,actor_id,request_key,request_hash,created_at FROM dbo.finance_movements WHERE tenant_id=@t AND id=@existing;
 RETURN;
 END;
 SELECT @balance=COALESCE(SUM(CASE WHEN kind='PAYMENT' THEN -CONVERT(decimal(38,0),amount_minor) ELSE CONVERT(decimal(38,0),amount_minor) END),0) FROM dbo.finance_movements WHERE tenant_id=@t AND patient_id=@pid;
 IF @kind='PAYMENT' AND @amount>@balance THROW 51003,'HP_CONFLICT:El pago excede el saldo pendiente',1;
 IF @kind='REFUND' BEGIN SELECT @paid=amount_minor FROM dbo.finance_movements WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@parent AND patient_id=@pid AND kind='PAYMENT' AND currency='PEN';
 SELECT @refunded=COALESCE(SUM(CONVERT(decimal(38,0),amount_minor)),0) FROM dbo.finance_movements WHERE tenant_id=@t AND parent_id=@parent AND kind='REFUND';
 IF @paid IS NULL OR @amount>CONVERT(decimal(38,0),@paid)-@refunded THROW 51003,'HP_CONFLICT:Devolucion superior al pago disponible',1;
 END ELSE IF @parent IS NOT NULL THROW 51000,'HP_INVALID:Solo devolucion referencia un pago',1;
 INSERT dbo.finance_movements(id,tenant_id,patient_id,kind,amount_minor,currency,title,parent_id,actor_id,request_key,request_hash) VALUES(@movement_id,@t,@pid,@kind,@amount,'PEN',@title,@parent,@u,@request_key,@request_hash);
 DECLARE @meta nvarchar(max)=(SELECT @kind kind,@amount amountMinor FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @t,N'FINANCE_POSTED',@movement_id,@meta;
 SELECT id,tenant_id,patient_id,kind,amount_minor,currency,title,parent_id,actor_id,request_key,request_hash,created_at FROM dbo.finance_movements WHERE tenant_id=@t AND id=@movement_id;
END;
GO
-- InventoryService.lots: 200 tenant lots in expiry/name order, full decimal quantity.
CREATE PROCEDURE dbo.usp_inventory_lots
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'ALM,FAR,AUD',N'INVENTORY';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 SELECT TOP(200) id,tenant_id,branch_id,name,lot,expiry,quantity,unit FROM dbo.stock_lots WHERE tenant_id=@t ORDER BY expiry,name,id;
END;
GO

-- InventoryService.transfers: tenant list, 200 complete transfer rows.
CREATE PROCEDURE dbo.usp_inventory_transfers
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'ALM,AUD',N'INVENTORY';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 SELECT TOP(200) id,tenant_id,lot_id,destination_branch_id,quantity,status,request_key,request_hash,created_at,received_at FROM dbo.stock_transfers WHERE tenant_id=@t ORDER BY created_at DESC,id;
END;
GO

-- InventoryService.prescriptions: FAR/PRO/AUD projection, no V5 encounter reader requiring PRO; full payload MAX.
CREATE PROCEDURE dbo.usp_inventory_prescriptions
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'FAR,PRO,AUD',N'PHARMACY';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 SELECT TOP(200) c.id,c.encounter_id,e.patient_id,e.branch_id,c.payload,c.created_at FROM dbo.clinical_entries c JOIN dbo.encounters e ON e.tenant_id=c.tenant_id AND e.id=c.encounter_id WHERE c.tenant_id=@t AND c.kind='PRESCRIPTION' ORDER BY c.created_at DESC,c.id;
END;
GO

-- InventoryService.lot / V4 sp_stock_lot: assigned active branch, starts at zero as existing contract, dates may be historical; unusable expired stock cannot be dispensed/transferred. RS lot.
CREATE PROCEDURE dbo.usp_inventory_lot_create @lot_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'ALM',N'INVENTORY',@write=1;
 EXEC dbo.usp_org_json_object @input,N'{"branchId":1,"name":1,"lot":1,"expiry":1,"unit":1}';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@branch nvarchar(max),@name nvarchar(max),@lot nvarchar(max),@expirytext nvarchar(max),@expiry date,@unit nvarchar(max),@b char(36);
 SELECT @branch=branchId,@name=name,@lot=lot,@expirytext=expiry,@unit=unit FROM OPENJSON(@input) WITH(branchId nvarchar(max),name nvarchar(max),lot nvarchar(max),expiry nvarchar(max),unit nvarchar(max));
 SET @expiry=TRY_CONVERT(date,@expirytext,23);
 IF @lot_id IS NULL OR DATALENGTH(@branch)<>72 OR TRY_CONVERT(uniqueidentifier,@branch) IS NULL OR NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR DATALENGTH(@name)>320 OR NULLIF(LTRIM(RTRIM(@lot)),N'') IS NULL OR DATALENGTH(@lot)>200 OR NULLIF(LTRIM(RTRIM(@unit)),N'') IS NULL OR DATALENGTH(@unit)>60 OR @expiry IS NULL OR DATALENGTH(@expirytext)<>20 OR CONVERT(nvarchar(10),@expiry,23)<>@expirytext THROW 51000,'HP_INVALID:Datos de lote invalidos',1;
 SET @b=CONVERT(char(36),@branch);
 EXEC dbo.usp_operations_branch @b;
 IF EXISTS(SELECT 1 FROM dbo.stock_lots WITH(UPDLOCK,HOLDLOCK) WHERE id=@lot_id OR tenant_id=@t AND branch_id=@b AND name=@name AND lot=@lot AND expiry=@expiry) THROW 51003,'HP_CONFLICT:Lote existente',1;
 INSERT dbo.stock_lots(id,tenant_id,branch_id,name,lot,expiry,quantity,unit) VALUES(@lot_id,@t,@b,@name,@lot,@expiry,0,@unit);
 EXEC dbo.usp_audit_event @t,N'STOCK_LOT_CREATED',@lot_id;
 SELECT id,tenant_id,branch_id,name,lot,expiry,quantity,unit FROM dbo.stock_lots WHERE tenant_id=@t AND id=@lot_id;
END;
GO

-- Quantities aggregate as DECIMAL(38,0) thousandths: DECIMAL(38,3) +/- can reduce scale to 2 under SQL Server precision rules. No rounding at the .001 boundary.
-- InventoryService.move / V4: lock lot and prescription before aggregate; exact quantity/unit, own patient prescription, stock never negative, exact retry returns existing row.
CREATE PROCEDURE dbo.usp_inventory_move @movement_id char(36),@input nvarchar(max),@request_key nvarchar(max),@request_hash char(64)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_idempotency @request_key,@request_hash;
 EXEC dbo.usp_operations_json @input,N'{"lotId":1,"kind":1,"quantity":2,"patientId":1,"prescriptionId":1}',N'["patientId","prescriptionId"]';
 DECLARE @kind nvarchar(max),@lottext nvarchar(max),@raw nvarchar(max),@patient nvarchar(max),@rx nvarchar(max),@qty decimal(14,3),@t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@stock decimal(14,3),@expiry date,@branch char(36),@name nvarchar(160),@unit nvarchar(30),@existing char(36),@hash char(64),@lot char(36);
 SELECT @kind=kind,@lottext=lotId,@raw=quantity,@patient=patientId,@rx=prescriptionId FROM OPENJSON(@input) WITH(kind nvarchar(max),lotId nvarchar(max),quantity nvarchar(max),patientId nvarchar(max),prescriptionId nvarchar(max));
 IF @kind COLLATE Latin1_General_100_BIN2 NOT IN ('RECEIVE','DISPENSE') OR DATALENGTH(@kind)<>2*LEN(@kind) OR @movement_id IS NULL OR DATALENGTH(@lottext)<>72 OR TRY_CONVERT(uniqueidentifier,@lottext) IS NULL OR (@patient IS NOT NULL AND (DATALENGTH(@patient)<>72 OR TRY_CONVERT(uniqueidentifier,@patient) IS NULL)) OR (@rx IS NOT NULL AND (DATALENGTH(@rx)<>72 OR TRY_CONVERT(uniqueidentifier,@rx) IS NULL)) THROW 51000,'HP_INVALID:Datos de movimiento invalidos',1;
 EXEC dbo.usp_operations_quantity @raw,@qty OUTPUT;
 IF @kind='DISPENSE' EXEC dbo.usp_operations_scope N'FAR',N'INVENTORY',@write=1;
 ELSE EXEC dbo.usp_operations_scope N'ALM',N'INVENTORY',@write=1;
 SET @lot=CONVERT(char(36),@lottext);
 SELECT @stock=quantity,@expiry=expiry,@branch=branch_id,@name=name,@unit=unit FROM dbo.stock_lots WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@lot;
 IF @stock IS NULL THROW 51002,'HP_NOT_FOUND:Lote inexistente',1;
 EXEC dbo.usp_operations_branch @branch;
 SELECT @existing=id,@hash=request_hash FROM dbo.stock_movements WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND request_key=@request_key;
 IF @existing IS NOT NULL BEGIN IF @hash<>@request_hash THROW 51003,'HP_CONFLICT:Clave utilizada con otros datos',1;
 SELECT id,tenant_id,lot_id,kind,quantity,patient_id,prescription_id,actor_id,request_key,request_hash,created_at FROM dbo.stock_movements WHERE tenant_id=@t AND id=@existing;
 RETURN;
 END;
 IF @patient IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1;
 IF @kind='DISPENSE' BEGIN EXEC dbo.usp_write_guard @t,N'PHARMACY';
 IF @patient IS NULL OR @rx IS NULL THROW 51000,'HP_INVALID:Dispensacion requiere paciente y prescripcion',1;
 DECLARE @payload nvarchar(max),@orderedraw nvarchar(max),@ordered decimal(14,3),@medication nvarchar(max),@rxunit nvarchar(max),@dispensed decimal(38,0);
 SELECT @payload=c.payload FROM dbo.clinical_entries c WITH(UPDLOCK,HOLDLOCK) JOIN dbo.encounters e ON e.tenant_id=c.tenant_id AND e.id=c.encounter_id WHERE c.tenant_id=@t AND c.id=@rx AND c.kind='PRESCRIPTION' AND e.patient_id=@patient;
 IF @payload IS NULL THROW 51002,'HP_NOT_FOUND:Prescripcion no disponible para paciente',1;
 SELECT @orderedraw=quantity,@medication=medication,@rxunit=unit FROM OPENJSON(@payload) WITH(quantity nvarchar(max),medication nvarchar(max),unit nvarchar(max));
 IF @medication IS NULL OR @rxunit IS NULL OR @medication COLLATE Latin1_General_100_BIN2<>@name COLLATE Latin1_General_100_BIN2 OR @rxunit COLLATE Latin1_General_100_BIN2<>@unit COLLATE Latin1_General_100_BIN2 OR DATALENGTH(@rxunit)<>DATALENGTH(@unit) THROW 51000,'HP_INVALID:Medicamento o unidad de prescripcion incompatible',1;
 EXEC dbo.usp_operations_quantity @orderedraw,@ordered OUTPUT;
 SELECT @dispensed=COALESCE(SUM(CONVERT(decimal(38,0),quantity*1000)),0) FROM dbo.stock_movements WHERE tenant_id=@t AND prescription_id=@rx AND kind='DISPENSE';
 IF CONVERT(decimal(38,0),@qty*1000)>CONVERT(decimal(38,0),@ordered*1000)-@dispensed THROW 51003,'HP_CONFLICT:Dispensacion superior al pendiente',1;
 IF @expiry<CONVERT(date,SYSUTCDATETIME()) OR @qty>@stock THROW 51003,'HP_CONFLICT:Lote vencido o stock insuficiente',1;
 UPDATE dbo.stock_lots SET quantity=quantity-@qty WHERE tenant_id=@t AND id=@lot;
 END
 ELSE BEGIN IF @rx IS NOT NULL THROW 51000,'HP_INVALID:Recepcion no admite prescripcion',1;
 IF CONVERT(decimal(38,0),@stock*1000)+CONVERT(decimal(38,0),@qty*1000)>CONVERT(decimal(38,0),99999999999999) THROW 51003,'HP_CONFLICT:Stock fuera de rango',1;
 UPDATE dbo.stock_lots SET quantity=quantity+@qty WHERE tenant_id=@t AND id=@lot;
 END;
 INSERT dbo.stock_movements(id,tenant_id,lot_id,kind,quantity,patient_id,prescription_id,actor_id,request_key,request_hash) VALUES(@movement_id,@t,@lot,@kind,@qty,@patient,@rx,@u,@request_key,@request_hash);
 DECLARE @meta nvarchar(max)=(SELECT @kind kind,@lot lotId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @t,N'STOCK_MOVED',@movement_id,@meta;
 SELECT id,tenant_id,lot_id,kind,quantity,patient_id,prescription_id,actor_id,request_key,request_hash,created_at FROM dbo.stock_movements WHERE tenant_id=@t AND id=@movement_id;
END;
GO

-- InventoryService.transfer / V4: reserve stock in source exactly once, both branches active/assigned and same tenant. Tenant UPDLOCK from guard gives deterministic shared lock order.
CREATE PROCEDURE dbo.usp_inventory_transfer_start @transfer_id char(36),@input nvarchar(max),@request_key nvarchar(max),@request_hash char(64)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'ALM',N'INVENTORY',@write=1;
 EXEC dbo.usp_operations_idempotency @request_key,@request_hash;
 EXEC dbo.usp_org_json_object @input,N'{"lotId":1,"destinationBranchId":1,"quantity":2}';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@lottext nvarchar(max),@desttext nvarchar(max),@raw nvarchar(max),@lot char(36),@dest char(36),@branch char(36),@stock decimal(14,3),@qty decimal(14,3),@expiry date,@existing char(36),@hash char(64);
 SELECT @lottext=lotId,@desttext=destinationBranchId,@raw=quantity FROM OPENJSON(@input) WITH(lotId nvarchar(max),destinationBranchId nvarchar(max),quantity nvarchar(max));
 IF @transfer_id IS NULL OR DATALENGTH(@lottext)<>72 OR TRY_CONVERT(uniqueidentifier,@lottext) IS NULL OR DATALENGTH(@desttext)<>72 OR TRY_CONVERT(uniqueidentifier,@desttext) IS NULL THROW 51000,'HP_INVALID:Datos de transferencia invalidos',1;
 EXEC dbo.usp_operations_quantity @raw,@qty OUTPUT;
 SET @lot=CONVERT(char(36),@lottext);
 SET @dest=CONVERT(char(36),@desttext);
 SELECT @branch=branch_id,@stock=quantity,@expiry=expiry FROM dbo.stock_lots WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@lot;
 IF @stock IS NULL THROW 51002,'HP_NOT_FOUND:Lote inexistente',1;
 EXEC dbo.usp_operations_branch @branch;
 EXEC dbo.usp_operations_branch @dest;
 SELECT @existing=id,@hash=request_hash FROM dbo.stock_transfers WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND request_key=@request_key;
 IF @existing IS NOT NULL BEGIN IF @hash<>@request_hash THROW 51003,'HP_CONFLICT:Clave utilizada con otros datos',1;
 SELECT id,tenant_id,lot_id,destination_branch_id,quantity,status,request_key,request_hash,created_at,received_at FROM dbo.stock_transfers WHERE tenant_id=@t AND id=@existing;
 RETURN;
 END;
 IF @branch=@dest OR @expiry<CONVERT(date,SYSUTCDATETIME()) OR @qty>@stock THROW 51003,'HP_CONFLICT:Destino invalido, lote vencido o stock insuficiente',1;
 UPDATE dbo.stock_lots SET quantity=quantity-@qty WHERE tenant_id=@t AND id=@lot;
 INSERT dbo.stock_transfers(id,tenant_id,lot_id,destination_branch_id,quantity,status,request_key,request_hash) VALUES(@transfer_id,@t,@lot,@dest,@qty,'IN_TRANSIT',@request_key,@request_hash);
 DECLARE @meta nvarchar(max)=(SELECT @lot lotId,@dest destinationBranchId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @t,N'TRANSFER_STARTED',@transfer_id,@meta;
 SELECT id,tenant_id,lot_id,destination_branch_id,quantity,status,request_key,request_hash,created_at,received_at FROM dbo.stock_transfers WHERE tenant_id=@t AND id=@transfer_id;
END;
GO

-- InventoryService.receive / active V7: source names/lot/expiry/unit copied explicitly; existing destination with different unit conflicts, no conversion/merge. Lock transfer+tenant and target range; replay RECEIVED has no effects.
CREATE PROCEDURE dbo.usp_inventory_transfer_receive @transfer_id char(36)
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
 END ELSE INSERT dbo.stock_lots(id,tenant_id,branch_id,name,lot,expiry,quantity,unit) VALUES(CONVERT(char(36),NEWID()),@t,@dest,@name,@lot,@expiry,@qty,@unit);
 UPDATE dbo.stock_transfers SET status='RECEIVED',received_at=SYSUTCDATETIME() WHERE tenant_id=@t AND id=@transfer_id;
 EXEC dbo.usp_audit_event @t,N'TRANSFER_RECEIVED',@transfer_id;
 END;
 SELECT id,tenant_id,lot_id,destination_branch_id,quantity,status,request_key,request_hash,created_at,received_at FROM dbo.stock_transfers WHERE tenant_id=@t AND id=@transfer_id;
END;
GO

-- HospitalService.resources: RS resource columns + occupied BIT, tenant-wide for ADM/PRO/ASI/AUD, TOP 200.
CREATE PROCEDURE dbo.usp_hospital_resources
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'ADM,PRO,ASI,AUD',N'HOSPITAL';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 SELECT TOP(200) r.id,r.tenant_id,r.branch_id,r.name,r.kind,r.active,
  CAST(CASE WHEN EXISTS(SELECT 1 FROM dbo.admissions a WHERE a.tenant_id=r.tenant_id AND a.resource_id=r.id AND a.status='ADMITTED') THEN 1 ELSE 0 END AS bit) occupied
 FROM dbo.hospital_resources r WHERE r.tenant_id=@t ORDER BY r.name,r.id;
END;
GO

-- HospitalService.resource / MySQL V4 sp_resource_create. RS full created resource; no existing resource activation/deactivation API is invented.
CREATE PROCEDURE dbo.usp_hospital_resource_create @resource_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'ADM',N'HOSPITAL',@write=1;
 EXEC dbo.usp_org_json_object @input,N'{"branchId":1,"name":1,"kind":1}';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@branchtext nvarchar(max),@name nvarchar(max),@kind nvarchar(max),@branch char(36),@domain nvarchar(6);
 SELECT @branchtext=branchId,@name=name,@kind=kind FROM OPENJSON(@input) WITH(branchId nvarchar(max),name nvarchar(max),kind nvarchar(max));
 IF @resource_id IS NULL OR DATALENGTH(@branchtext)<>72 OR TRY_CONVERT(uniqueidentifier,@branchtext) IS NULL
  OR NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR DATALENGTH(@name)>200
  OR @kind COLLATE Latin1_General_100_BIN2 NOT IN ('BED','CAGE') OR DATALENGTH(@kind)<>2*LEN(@kind)
  THROW 51000,'HP_INVALID:Datos del recurso invalidos',1;
 SET @branch=CONVERT(char(36),@branchtext); EXEC dbo.usp_operations_branch @branch;
 SELECT @domain=domain FROM dbo.tenants WHERE id=@t;
 IF (@domain='HUMAN' AND @kind<>'BED') OR (@domain='ANIMAL' AND @kind<>'CAGE')
  THROW 51000,'HP_INVALID:Tipo de recurso incompatible con el dominio',1;
 IF EXISTS(SELECT 1 FROM dbo.hospital_resources WITH(UPDLOCK,HOLDLOCK) WHERE id=@resource_id OR (tenant_id=@t AND branch_id=@branch AND name=@name))
  THROW 51003,'HP_CONFLICT:Recurso existente en la sede',1;
 INSERT dbo.hospital_resources(id,tenant_id,branch_id,name,kind) VALUES(@resource_id,@t,@branch,@name,@kind);
 EXEC dbo.usp_audit_event @t,N'HOSPITAL_RESOURCE_CREATED',@resource_id;
 SELECT id,tenant_id,branch_id,name,kind,active FROM dbo.hospital_resources WHERE tenant_id=@t AND id=@resource_id;
END;
GO

-- HospitalService.admissions: RS full admissions including existing computed active keys; TOP 200, tenant-wide, no patient clinical body.
CREATE PROCEDURE dbo.usp_hospital_admissions
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'PRO,ASI,AUD',N'HOSPITAL';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 SELECT TOP(200) id,tenant_id,patient_id,resource_id,status,reason,revision,admitted_at,discharged_at,occupied_resource,admitted_patient
 FROM dbo.admissions WHERE tenant_id=@t ORDER BY admitted_at DESC,id;
END;
GO

-- HospitalService.admit (including resource branch lookup) / MySQL V4 sp_admit. RS created admission; tenant guard then patient/resource locks plus filtered unique constraints.
CREATE PROCEDURE dbo.usp_hospital_admit @admission_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'PRO,ASI',N'HOSPITAL',@write=1;
 EXEC dbo.usp_org_json_object @input,N'{"patientId":1,"resourceId":1,"reason":1}';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@patienttext nvarchar(max),@resourcetext nvarchar(max),@reason nvarchar(max),@patient char(36),@resource char(36),@branch char(36),@kind nvarchar(4),@active bit,@domain nvarchar(6),@patientdomain nvarchar(6);
 SELECT @patienttext=patientId,@resourcetext=resourceId,@reason=reason FROM OPENJSON(@input) WITH(patientId nvarchar(max),resourceId nvarchar(max),reason nvarchar(max));
 IF @admission_id IS NULL OR DATALENGTH(@patienttext)<>72 OR TRY_CONVERT(uniqueidentifier,@patienttext) IS NULL OR DATALENGTH(@resourcetext)<>72 OR TRY_CONVERT(uniqueidentifier,@resourcetext) IS NULL
  OR NULLIF(LTRIM(RTRIM(@reason)),N'') IS NULL OR DATALENGTH(@reason)>2000
  THROW 51000,'HP_INVALID:Datos de estancia invalidos',1;
 SELECT @patient=id,@patientdomain=domain FROM dbo.patients WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@patienttext;
 SELECT @resource=id,@branch=branch_id,@kind=kind,@active=active FROM dbo.hospital_resources WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@resourcetext;
 IF @patient IS NULL OR @resource IS NULL OR @active<>1 THROW 51002,'HP_NOT_FOUND:Paciente o recurso activo inexistente',1;
 EXEC dbo.usp_operations_branch @branch; SELECT @domain=domain FROM dbo.tenants WHERE id=@t;
 IF @patientdomain<>@domain OR (@domain='HUMAN' AND @kind<>'BED') OR (@domain='ANIMAL' AND @kind<>'CAGE') THROW 51000,'HP_INVALID:Dominio de paciente o recurso incompatible',1;
 IF EXISTS(SELECT 1 FROM dbo.admissions WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND status='ADMITTED' AND (resource_id=@resource OR patient_id=@patient))
  THROW 51003,'HP_CONFLICT:El recurso o paciente tiene una estancia activa',1;
 IF EXISTS(SELECT 1 FROM dbo.admissions WHERE id=@admission_id) THROW 51003,'HP_CONFLICT:Estancia existente',1;
 INSERT dbo.admissions(id,tenant_id,patient_id,resource_id,status,reason) VALUES(@admission_id,@t,@patient,@resource,'ADMITTED',@reason);
 DECLARE @meta nvarchar(max)=(SELECT @resource resourceId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @t,N'PATIENT_ADMITTED',@admission_id,@meta;
 SELECT id,tenant_id,patient_id,resource_id,status,reason,revision,admitted_at,discharged_at,occupied_resource,admitted_patient FROM dbo.admissions WHERE tenant_id=@t AND id=@admission_id;
END;
GO

-- HospitalService.discharge + branch lookup / MySQL V4 sp_discharge. RS revised admission, never closes encounters or removes histories.
CREATE PROCEDURE dbo.usp_hospital_discharge @admission_id char(36),@expected_revision int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_scope N'PRO,ASI',N'HOSPITAL',@write=1;
 IF @admission_id IS NULL OR @expected_revision IS NULL OR @expected_revision<1 THROW 51000,'HP_INVALID:Revision de estancia requerida',1;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@resource char(36),@branch char(36),@rev int,@state nvarchar(10);
 SELECT @resource=resource_id,@rev=revision,@state=status FROM dbo.admissions WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@admission_id;
 IF @resource IS NULL THROW 51002,'HP_NOT_FOUND:Estancia inexistente',1;
 SELECT @branch=branch_id FROM dbo.hospital_resources WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@resource;
 EXEC dbo.usp_operations_branch @branch;
 IF @rev<>@expected_revision OR @state<>'ADMITTED' OR @rev=2147483647 THROW 51003,'HP_CONFLICT:Estancia cerrada o revision desactualizada',1;
 UPDATE dbo.admissions SET status='DISCHARGED',discharged_at=SYSUTCDATETIME(),revision=revision+1 WHERE tenant_id=@t AND id=@admission_id;
 EXEC dbo.usp_audit_event @t,N'PATIENT_DISCHARGED',@admission_id;
 SELECT id,tenant_id,patient_id,resource_id,status,reason,revision,admitted_at,discharged_at,occupied_resource,admitted_patient FROM dbo.admissions WHERE tenant_id=@t AND id=@admission_id;
END;
GO

-- PRIVATE WorkflowService.definition + Access.roles/module/write. Permissions derive ONLY from server definitions and current DB membership; never from request roles.
-- No resultset. @permission is an INTERNAL selector, not executable SQL or a definition supplied by the caller.
CREATE PROCEDURE dbo.usp_operations_workflow_guard @type nvarchar(max),@permission varchar(10),@write bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor;
 IF CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')) IS NULL THROW 51001,'HP_FORBIDDEN:Se requiere sesion tenant',1;
 IF @type IS NULL OR NULLIF(LTRIM(RTRIM(@type)),N'') IS NULL OR DATALENGTH(@type)>120 OR @permission IS NULL OR @permission COLLATE Latin1_General_100_BIN2 NOT IN ('READ','CREATE','OPERATE')
  THROW 51000,'HP_INVALID:Tipo o permiso de proceso invalido',1;
 DECLARE @module nvarchar(40),@rolesjson nvarchar(max),@roles nvarchar(max);
 SELECT @module=module,@rolesjson=CASE @permission WHEN 'READ' THEN readers WHEN 'CREATE' THEN creators ELSE operators END
 FROM dbo.workflow_definitions WHERE type COLLATE Latin1_General_100_BIN2=@type COLLATE Latin1_General_100_BIN2 AND DATALENGTH(type)=DATALENGTH(@type);
 IF @module IS NULL THROW 51002,'HP_NOT_FOUND:Tipo de proceso inexistente',1;
 IF ISJSON(@rolesjson,ARRAY)<>1 OR EXISTS(SELECT 1 FROM OPENJSON(@rolesjson) WHERE type<>1 OR value COLLATE Latin1_General_100_BIN2 NOT IN ('ADM','PRO','ASI','REC','CAJ','ALM','FAR','DIA','AUD','PAC','RES'))
  THROW 51000,'HP_INVALID:Definicion de permisos de proceso invalida',1;
 SELECT @roles=STRING_AGG(CONVERT(nvarchar(max),value),N',') FROM OPENJSON(@rolesjson);
 IF @roles IS NULL OR DATALENGTH(@roles)>400 THROW 51001,'HP_FORBIDDEN:Proceso sin permiso disponible',1;
 DECLARE @bounded nvarchar(200)=@roles;
 EXEC dbo.usp_operations_scope @bounded,@module,@write;
END;
GO

-- WorkflowService.definitions: RS type,module,patient_required,animal_only,creators,operators,readers,transitions (JSON text), filtered by actual modules/current membership readers.
-- Existing definitions contain role arrays/transitions only, no conditions/requiredData engine. No new laboratory/surgery/provider effects are implied.
CREATE PROCEDURE dbo.usp_workflow_definitions
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id'));
 IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Se requiere sesion tenant',1;
 SELECT d.type,d.module,d.patient_required,d.animal_only,d.creators,d.operators,d.readers,d.transitions
 FROM dbo.workflow_definitions d
 WHERE EXISTS(SELECT 1 FROM dbo.subscriptions s JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version CROSS APPLY OPENJSON(v.modules) j WHERE s.tenant_id=@t AND j.value COLLATE Latin1_General_100_BIN2=d.module COLLATE Latin1_General_100_BIN2)
 AND EXISTS(SELECT 1 FROM dbo.memberships m CROSS APPLY OPENJSON(m.roles) r JOIN OPENJSON(d.readers) allowed ON r.value COLLATE Latin1_General_100_BIN2=allowed.value COLLATE Latin1_General_100_BIN2 WHERE m.tenant_id=@t AND m.user_id=@u AND m.status='ACTIVE')
 ORDER BY d.type;
END;
GO

-- WorkflowService.list(type) + private definition lookup: RS full workflow case columns, TOP 200, immutable full JSON text.
CREATE PROCEDURE dbo.usp_workflow_list @type nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_operations_workflow_guard @type,'READ';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 SELECT TOP(200) id,tenant_id,branch_id,patient_id,type,status,title,payload,revision,actor_id,created_at,updated_at
 FROM dbo.workflow_cases WHERE tenant_id=@t AND type COLLATE Latin1_General_100_BIN2=@type COLLATE Latin1_General_100_BIN2 ORDER BY updated_at DESC,id;
END;
GO

-- WorkflowService.get: RS1 full own case; RS2 history{revision,status,payload,actor_id,created_at} ordered revision; Java assembles history array without JSON stringification/truncation.
CREATE PROCEDURE dbo.usp_workflow_get @case_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@type nvarchar(60);
 IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Se requiere sesion tenant',1;
 SELECT @type=type FROM dbo.workflow_cases WHERE tenant_id=@t AND id=@case_id;
 IF @type IS NULL THROW 51002,'HP_NOT_FOUND:Proceso inexistente',1;
 EXEC dbo.usp_operations_workflow_guard @type,'READ';
 SELECT id,tenant_id,branch_id,patient_id,type,status,title,payload,revision,actor_id,created_at,updated_at FROM dbo.workflow_cases WHERE tenant_id=@t AND id=@case_id;
 SELECT revision,status,payload,actor_id,created_at FROM dbo.workflow_history WHERE tenant_id=@t AND case_id=@case_id ORDER BY revision;
END;
GO

-- WorkflowService.create / V4 sp_workflow_create: input exact Requests.Create; RS1 case + RS2 history as get. Payload object MAX, Spring retains Checks.json 200000 UTF16/depth30 validation.
CREATE PROCEDURE dbo.usp_workflow_create @case_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor;
 EXEC dbo.usp_operations_json @input,N'{"type":1,"branchId":1,"patientId":1,"title":1,"payload":5}',N'["patientId"]';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@type nvarchar(max),@branchtext nvarchar(max),@patienttext nvarchar(max),@title nvarchar(max),@payload nvarchar(max),@branch char(36),@patient char(36),@needs bit,@animal bit;
 SELECT @type=type,@branchtext=branchId,@patienttext=patientId,@title=title,@payload=payload FROM OPENJSON(@input) WITH(type nvarchar(max),branchId nvarchar(max),patientId nvarchar(max),title nvarchar(max),payload nvarchar(max) AS JSON);
 IF @case_id IS NULL OR DATALENGTH(@branchtext)<>72 OR TRY_CONVERT(uniqueidentifier,@branchtext) IS NULL
  OR (@patienttext IS NOT NULL AND (DATALENGTH(@patienttext)<>72 OR TRY_CONVERT(uniqueidentifier,@patienttext) IS NULL))
  OR NULLIF(LTRIM(RTRIM(@title)),N'') IS NULL OR DATALENGTH(@title)>400 OR @payload IS NULL OR ISJSON(@payload,OBJECT)<>1 OR DATALENGTH(@payload)>400000
  THROW 51000,'HP_INVALID:Datos de proceso invalidos',1;
 EXEC dbo.usp_operations_workflow_guard @type,'CREATE',@write=1;
 EXEC dbo.usp_operations_workflow_guard @type,'READ';
 SET @branch=CONVERT(char(36),@branchtext); SET @patient=CONVERT(char(36),@patienttext);
 EXEC dbo.usp_operations_branch @branch;
 SELECT @needs=patient_required,@animal=animal_only FROM dbo.workflow_definitions WHERE type COLLATE Latin1_General_100_BIN2=@type COLLATE Latin1_General_100_BIN2;
 IF @needs=1 AND @patient IS NULL THROW 51000,'HP_INVALID:El proceso requiere un paciente',1;
 IF @patient IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.patients WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@patient) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1;
 IF @animal=1 AND NOT EXISTS(SELECT 1 FROM dbo.tenants WHERE id=@t AND domain='ANIMAL') THROW 51001,'HP_FORBIDDEN:Proceso exclusivo de veterinaria',1;
 IF EXISTS(SELECT 1 FROM dbo.workflow_cases WHERE id=@case_id) THROW 51003,'HP_CONFLICT:Proceso existente',1;
 INSERT dbo.workflow_cases(id,tenant_id,branch_id,patient_id,type,status,title,payload,actor_id) VALUES(@case_id,@t,@branch,@patient,@type,'DRAFT',@title,@payload,@u);
 INSERT dbo.workflow_history(tenant_id,case_id,revision,status,payload,actor_id) VALUES(@t,@case_id,1,'DRAFT',@payload,@u);
 DECLARE @meta nvarchar(max)=(SELECT @type type FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @t,N'WORKFLOW_CREATED',@case_id,@meta;
 EXEC dbo.usp_workflow_get @case_id;
END;
GO

-- WorkflowService.step / V4 sp_workflow_step: typed expected revision/status, JSON object payload MAX. RS1 revised case + RS2 full history; terminal states cannot advance without a server definition transition.
-- No autonomous commits; tenant write guard serializes mutations before case locks. Revision is re-read under lock; history has no mutating/deleting procedure.
CREATE PROCEDURE dbo.usp_workflow_step @case_id char(36),@expected_revision int,@next_status nvarchar(max),@payload nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor;
 IF @case_id IS NULL OR @expected_revision IS NULL OR @expected_revision<1 OR NULLIF(LTRIM(RTRIM(@next_status)),N'') IS NULL OR DATALENGTH(@next_status)>80 OR DATALENGTH(@next_status)<>2*LEN(@next_status)
  OR @payload IS NULL OR ISJSON(@payload,OBJECT)<>1 OR DATALENGTH(@payload)>400000
  THROW 51000,'HP_INVALID:Estado, revision o contenido de proceso invalido',1;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@type nvarchar(60),@branch char(36),@state nvarchar(40),@rev int,@steps nvarchar(max),@permission varchar(10);
 IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Se requiere sesion tenant',1;
 SELECT @type=type,@state=status FROM dbo.workflow_cases WHERE tenant_id=@t AND id=@case_id;
 IF @type IS NULL THROW 51002,'HP_NOT_FOUND:Proceso inexistente',1;
 EXEC dbo.usp_operations_workflow_guard @type,'READ';
 SET @permission=CASE WHEN @state COLLATE Latin1_General_100_BIN2='DRAFT' AND @next_status COLLATE Latin1_General_100_BIN2='SUBMITTED' THEN 'CREATE' ELSE 'OPERATE' END;
 EXEC dbo.usp_operations_workflow_guard @type,@permission,@write=1;
 SELECT @state=status,@rev=revision,@branch=branch_id FROM dbo.workflow_cases WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@case_id;
 IF @rev<>@expected_revision OR @rev=2147483647 THROW 51003,'HP_CONFLICT:Revision del proceso desactualizada',1;
 -- Re-evaluate definition permission under the locked current state, never a stale pre-lock snapshot.
 SET @permission=CASE WHEN @state COLLATE Latin1_General_100_BIN2='DRAFT' AND @next_status COLLATE Latin1_General_100_BIN2='SUBMITTED' THEN 'CREATE' ELSE 'OPERATE' END;
 EXEC dbo.usp_operations_workflow_guard @type,@permission;
 EXEC dbo.usp_operations_branch @branch;
 SELECT @steps=transitions FROM dbo.workflow_definitions WHERE type COLLATE Latin1_General_100_BIN2=@type COLLATE Latin1_General_100_BIN2;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@steps) states CROSS APPLY OPENJSON(CASE WHEN states.type=4 THEN states.value ELSE N'[]' END) allowed
 WHERE states.[key] COLLATE Latin1_General_100_BIN2=@state COLLATE Latin1_General_100_BIN2 AND allowed.type=1 AND allowed.value COLLATE Latin1_General_100_BIN2=@next_status COLLATE Latin1_General_100_BIN2 AND DATALENGTH(allowed.value)=DATALENGTH(@next_status))
  THROW 51003,'HP_CONFLICT:Transicion de estado no permitida',1;
 UPDATE dbo.workflow_cases SET status=@next_status,payload=@payload,revision=revision+1,updated_at=SYSUTCDATETIME(),actor_id=@u WHERE tenant_id=@t AND id=@case_id;
 INSERT dbo.workflow_history(tenant_id,case_id,revision,status,payload,actor_id) VALUES(@t,@case_id,@rev+1,@next_status,@payload,@u);
 DECLARE @meta nvarchar(max)=(SELECT @next_status status,@rev+1 revision FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @t,N'WORKFLOW_ADVANCED',@case_id,@meta;
 EXEC dbo.usp_workflow_get @case_id;
END;
GO

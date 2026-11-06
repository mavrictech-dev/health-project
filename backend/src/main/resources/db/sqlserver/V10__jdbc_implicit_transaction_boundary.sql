-- Microsoft JDBC setAutoCommit(false) enables IMPLICIT_TRANSACTIONS. EXEC and
-- session-context assignments alone do not materialize that transaction.
-- A write-first REQUIRED unit must not depend on a preceding business read.
-- Only materialize a caller-selected implicit transaction; autocommit callers
-- still fail. Never BEGIN/COMMIT here: Spring retains the complete unit of work.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE dbo.usp_require_transaction
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT=0 AND (@@OPTIONS & 2)=2
 BEGIN
  DECLARE @revision int;
  SELECT @revision=revision FROM dbo.application_state WHERE id=1;
 END;
 IF @@TRANCOUNT=0 THROW 51000,'HP_INVALID:External transaction required',1;
END;
GO

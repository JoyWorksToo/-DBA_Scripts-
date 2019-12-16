declare @merchantIdentifier int
declare @referenceDate datetime
set @merchantIdentifier=151227116
set @referenceDate='2016-11-26 00:00:00'

SELECT
    'IdConfirmedTransaction' = act.ID_CONFIRMED_TRANSACTION,
    'InstallmentNumber' = act.INSTALLMENT_NUMBER,
    'AcquirerTransactionKey' = act.ACQUIRER_TRANSACTION_KEY,
    'GrossAmount' = act.ORIGINAL_AMOUNT,
    'NetAmount' = SUM(
        CASE WHEN mov.BUY4_MOVEMENT_CATEGORY = 6 AND cast(mov.ENTRY_DATE AS DATE) = @referenceDate
          THEN -MOV.AMOUNT
        WHEN mov.[OPERATION_CODE] = 1 AND mov.BUY4_MOVEMENT_CATEGORY != 6
          THEN +mov.[AMOUNT]
        WHEN mov.[OPERATION_CODE] = 2 AND mov.BUY4_MOVEMENT_CATEGORY != 6
          THEN -mov.[AMOUNT]
        ELSE 0
        END),
    'SettlementDate' = max(mov.SETTLEMENT_DATE),
    'LastModifiedDate' = max(mov.LAST_MODIFIED_DATE),
    'PaymentId' = mov.ID_SETTLEMENT_EVENT,
    'TransactionCaptureLocalDateTime' = act.PRESENTATION_DATE,
    'IdSettlementEvent' = mov.ID_SETTLEMENT_EVENT

FROM ATX_CONFIRMED_TRANSACTION act ( NOLOCK )
  INNER JOIN ATX_TX_MOVEMENT_DETAIL movd ( NOLOCK ) ON act.ID_CONFIRMED_TRANSACTION = movd.ID_CONFIRMED_TRANSACTION
  INNER JOIN AMR_MOVEMENT mov ( NOLOCK ) ON movd.ID_MOVEMENT = mov.ID_MOVEMENT
  INNER JOIN BUY4_SETTLEMENT_EVENT se ( NOLOCK ) ON se.Id = mov.ID_SETTLEMENT_EVENT
  INNER JOIN BUY4_MOVEMENT_TYPE AS mt ( NOLOCK ) ON mov.BUY4_MOVEMENT_CATEGORY = mt.ID_BUY4_MOVEMENT_CATEGORY
  --LEFT JOIN .pay.Payment pm ( NOLOCK ) ON se.Id = pm.SettlementEventId
  INNER JOIN AMR_MERCHANT m ( NOLOCK ) ON mov.ID_MERCHANT = m.ID_MERCHANT
										--AND m.ID_MERCHANT = act.ID_MERCHANT
WHERE mov.MOVEMENT_TYPE IN (3, 4)
      AND mov.ID_ORIGINAL_MOVEMENT IS NULL
      AND cast(se.SettlementDate AS DATE) = cast(@referenceDate AS DATE)
      AND m.MERCHANT_IDENTIFIER = @merchantIdentifier
      AND act.TX_TYPE = 1
      AND mov.BUY4_MOVEMENT_CATEGORY NOT IN (20, 21)
	--  AND se.PaymentStatusId in (20, 30, 50)
GROUP BY act.ID_CONFIRMED_TRANSACTION,
  act.INSTALLMENT_NUMBER,
  act.ACQUIRER_TRANSACTION_KEY,
  act.ORIGINAL_AMOUNT,
  act.PRESENTATION_DATE,
  mov.ID_SETTLEMENT_EVENT
  
  
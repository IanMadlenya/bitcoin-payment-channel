module PaymentChannel.Internal.Payment.Create
(
  mkUnsignedPayment
, createPaymentOfValue
, module Export
)
where

import PaymentChannel.Internal.Payment.Types as Export

-- import RBPCP.Types
import PaymentChannel.Internal.RBPCP.Parse
import PaymentChannel.Internal.Types
import PaymentChannel.Internal.ChanScript
import Bitcoin.Util
import Bitcoin.SinglePair
import Bitcoin.Compare
import PaymentChannel.Internal.Util

import qualified Network.Haskoin.Transaction as HT
import qualified Network.Haskoin.Crypto as HC
import qualified Network.Haskoin.Script as HS
import qualified Data.List.NonEmpty     as NE



mkUnsignedPayment :: ChanParams -> FundingTxInfo -> HC.Address -> Payment ()
mkUnsignedPayment cp CFundingTxInfo{..} refundAddr =
    mkSigSinglePair fundingIn changeOut
  where
    changeOut = mkBtcOut refundAddr ftiOutValue
    fundingIn = mkNoSigTxIn (HT.OutPoint ftiHash ftiOutIndex)
                            (nonDusty ftiOutValue)
                            (Pay2 $ ScriptHash $ Cond cp)

createPaymentOfValue :: ( Monad m, Show t
                        , TransformSigData BtcSig () r
                        , SignatureScript t BtcSig
                        , SpendFulfillment BtcSig r
                        , HasSpendCond r t
                        ) =>
       HC.PrvKeyC
    -> SigSinglePair t ()
    -> BtcAmount
    -> m (Either BtcError (SigSinglePair t BtcSig))
createPaymentOfValue prvKey ssp payVal =
    either (return . Left) (signPair prvKey) (decrementClientValue ssp payVal)

decrementClientValue :: SigSinglePair r () -> BtcAmount -> Either BtcError (SigSinglePair r ())
decrementClientValue sp@SigSinglePair{..} decVal = do
    newVal <- mkNonDusty (currentVal - decVal)
    Right $ sp { singleOutput = replaceValue singleOutput newVal }
  where
    currentVal = nonDusty $ btcAmount singleOutput
    replaceValue out val = out { btcAmount = val }

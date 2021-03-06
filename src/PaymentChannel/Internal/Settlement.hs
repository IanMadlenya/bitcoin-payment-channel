{-# LANGUAGE RecordWildCards, FlexibleContexts #-}
module PaymentChannel.Internal.Settlement
-- (
--     createSignedSettlementTx
-- ,   settleReceivedValue
-- ,   UnsignedSettlementTx, mkUnsignedSettleData
-- )
where

import PaymentChannel.Internal.Settlement.Util
import PaymentChannel.Internal.Receiver.Util
import PaymentChannel.Internal.Payment
import Bitcoin.Util
import Bitcoin.Types
import Bitcoin.Fee
import PaymentChannel.Types                    (fundingAddress)
import PaymentChannel.Internal.Class.Value     (HasValue(..))
import PaymentChannel.Internal.Error.Internal

import qualified Network.Haskoin.Transaction as HT
import qualified Network.Haskoin.Crypto as HC
import qualified Data.List.NonEmpty     as NE
{-# ANN module ("HLint: ignore Use mapMaybe"::String) #-}



type SignedTx = BtcTx ScriptType PaymentScriptSig


mkUnsignedSettleData ::
       NE.NonEmpty ServerPayChanX
    -> [BtcOut]
    -> ClientSignedTx
mkUnsignedSettleData rpcL extraOuts =
    txAddOuts extraOuts $ toClientSignedTx payLst
        where payLst = NE.map (pcsPayment . rpcState) rpcL

class HasKeyDeriveIndex kd where     
    mkExtendedSettleRPC :: ServerPayChanI kd -> ServerPayChanI KeyDeriveIndex     

instance HasKeyDeriveIndex KeyDeriveIndex where      
    mkExtendedSettleRPC = id

instance HasKeyDeriveIndex () where     
    mkExtendedSettleRPC = mkDummyExtendedRPC

getSignedSettlementTx ::
       (Monad m, HasKeyDeriveIndex kd)
    => ServerPayChanI kd
    -> (KeyDeriveIndex -> m HC.PrvKeyC) -- ^ Server/receiver's signing key.
    -> ChangeOut
    -> m (Either ReceiverError SignedTx)
getSignedSettlementTx rpc signFunc chgOut =
    let
        dummyExtRPC = mkExtendedSettleRPC rpc :| []
        settleData  = mkUnsignedSettleData dummyExtRPC []
    in
        fmapL SettleSigningError <$> signSettleTx signFunc chgOut settleData







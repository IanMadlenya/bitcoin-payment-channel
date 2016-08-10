module Data.Bitcoin.PaymentChannel.Internal.Error where

import Data.Bitcoin.PaymentChannel.Internal.Types (BitcoinAmount)

data PayChanError =
    BadSignature |
    BadPaymentValue BitcoinAmount   |
    NoValueTransferred |
    DustOutput |
    InternalError String

instance Show PayChanError where
    show BadSignature = "signature verification failed"
    show (BadPaymentValue valDiff) =
        "out-of-order payment (assigns " ++ show valDiff ++ " less value to server)"
    show DustOutput = "dust output in payment transaction"
    show NoValueTransferred = "cannot create payment Bitcoin transaction: no\
    \ value has been transferred yet"
    show (InternalError e) = "Internal error: " ++ e


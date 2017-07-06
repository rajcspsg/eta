{-# LANGUAGE Trustworthy #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  System.Exit
-- Copyright   :  (c) The University of Glasgow 2001
-- License     :  BSD-style (see the file libraries/base/LICENSE)
--
-- Maintainer  :  libraries@haskell.org
-- Stability   :  provisional
-- Portability :  portable
--
-- Exiting the program.
--
-----------------------------------------------------------------------------

module System.Exit
    (
      ExitCode(ExitSuccess,ExitFailure)
    , exitWith
    , exitFailure
    , exitSuccess
    , die
  ) where

import System.IO

import GHC.IO
import GHC.IO.Exception

-- ---------------------------------------------------------------------------
-- exitWith

-- | Computation 'exitWith' @code@ throws 'ExitCode' @code@.
-- Normally this terminates the program, returning @code@ to the
-- program's caller.
--
-- On program termination, the standard 'Handle's 'stdout' and
-- 'stderr' are flushed automatically; any other buffered 'Handle's
-- need to be flushed manually, otherwise the buffered data will be
-- discarded.
--
-- A program that fails in any other way is treated as if it had
-- called 'exitFailure'.
-- A program that terminates successfully without calling 'exitWith'
-- explicitly is treated as it it had called 'exitWith' 'ExitSuccess'.
--
-- As an 'ExitCode' is not an 'IOError', 'exitWith' bypasses
-- the error handling in the 'IO' monad and cannot be intercepted by
-- 'catch' from the "Prelude".  However it is a 'SomeException', and can
-- be caught using the functions of "Control.Exception".  This means
-- that cleanup computations added with 'Control.Exception.bracket'
-- (from "Control.Exception") are also executed properly on 'exitWith'.
--
-- Note: in GHC, 'exitWith' should be called from the main program
-- thread in order to exit the process.  When called from another
-- thread, 'exitWith' will throw an 'ExitException' as normal, but the
-- exception will not cause the process itself to exit.
--
exitWith :: ExitCode -> IO a
exitWith code =
  case mExitCode of
    Just exitCode -> shutdownAndExit exitCode False >> return undefined
    Nothing       -> ioError (IOError Nothing InvalidArgument
                                      "exitWith" "ExitFailure 0" Nothing Nothing)
  where mExitCode = case code of
          ExitSuccess   -> Just 0
          ExitFailure n
            | n == 0    -> Nothing
            | otherwise -> Just n

foreign import java "@static eta.runtime.Runtime.shutdownAndExit"
  shutdownAndExit :: Int -> Bool -> IO ()

-- | The computation 'exitFailure' is equivalent to
-- 'exitWith' @(@'ExitFailure' /exitfail/@)@,
-- where /exitfail/ is implementation-dependent.
exitFailure :: IO a
exitFailure = exitWith (ExitFailure 1)

-- | The computation 'exitSuccess' is equivalent to
-- 'exitWith' 'ExitSuccess', It terminates the program
-- successfully.
exitSuccess :: IO a
exitSuccess = exitWith ExitSuccess

-- | Write given error message to `stderr` and terminate with `exitFailure`.
--
-- @since 4.8.0.0
die :: String -> IO a
die err = hPutStrLn stderr err >> exitFailure

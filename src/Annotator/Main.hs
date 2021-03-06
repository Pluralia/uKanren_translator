{-# LANGUAGE TupleSections #-}
module Annotator.Main (
    preTranslate
  ) where


import qualified Eval             as E
import           Syntax
import qualified Unfold           as U

import           Annotator.Internal.Core
import           Annotator.Internal.Gen
import           Annotator.Internal.Lib
import           Annotator.Internal.Normalization
import           Annotator.Internal.Stack
import           Annotator.Internal.Types
import           Annotator.Types

import           Debug.Trace           (trace)


----------------------------------------------------------------------------------------------------

preTranslate :: Program -> [X] -> [AnnDef]
preTranslate program inX =
  let
      (Program scope goal)  = normalizeInvokes program
      gamma                 = trace ("SCOPE: " ++ (show scope)) $ E.updateDefsInGamma E.env0 scope
      (initGamma, initGoal) = initTranslation gamma goal inX
      (_, stack)            = annotate initGamma initGoal
      maybeGenStack         =
        maybe (maybeStack . annotateStackWithGen gamma $ stack) Just . maybeStack $ stack
      beautifulStack        =
        maybe (error "annotateStackWithGen: fail gen") makeStackBeauty maybeGenStack
   in trace ("STACK: " ++ (show stack) ++ "\n\n" ++ (show . fmap (\(AnnDef name _ _) -> name) $ beautifulStack)) $
      beautifulStack

----------------------------------------------------------------------------------------------------

-- trace ("Iota before init: " ++ E.showInt iota)
initTranslation ::  E.Gamma -> G X -> [X] -> (E.Gamma, [[G (S, Ann)]])
initTranslation gamma goal inX =
  let
      (unfreshedGoal, gamma', _) = E.preEval gamma goal
      (_, iota'@(_, xToTs), _)   = gamma'
      inS                        = (getVarsT . xToTs) `concatMap` inX
      normalizedGoal             = U.normalize unfreshedGoal
      normUnifGoal               = normalizeUnif normalizedGoal
      preAnnotatedGoal           = fmap (initAnns inS) <$> normUnifGoal
   in (gamma', preAnnotatedGoal)
  where
    initAnns :: [S] -> G S -> G (S, Ann)
    initAnns inS = fmap (\s -> (s, if s `elem` inS then Just 0 else Nothing))

----------------------------------------------------------------------------------------------------

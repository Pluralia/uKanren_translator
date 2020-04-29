{-# LANGUAGE TupleSections #-}
module Annotator.Internal.Stack (
    addToStack
  , disjPerm
  , disjStackPred
  , filterStack
  ) where


import qualified Data.Map.Strict  as M
import           Data.Maybe            (fromMaybe, isJust, catMaybes, isNothing)
import           Data.List             (permutations, partition)
import qualified Data.Set         as S

import           Syntax

import           Annotator.Internal.Lib
import           Annotator.Internal.Types

import           Debug.Trace           (trace)

----------------------------------------------------------------------------------------------------

addToStack :: Stack -> Name -> [Term (S, Ann)] -> [[G (S, Ann)]] -> Stack
addToStack stack name terms goal = trace ("addToStack: " ++ name ++ " | " ++ show terms ++ " | " ++ show (argsOrder terms goal)) $
  let updArgsOrderSet = S.insert (argsOrder terms goal) . fromMaybe S.empty $ M.lookup name stack
   in M.insert name updArgsOrderSet stack


filterStack :: Stack -> Stack
filterStack stack = fmap (errorIfUndefStack . S.filter argsOrderPred) stack
  where
    errorIfUndefStack :: S.Set ArgsOrder -> S.Set ArgsOrder
    errorIfUndefStack set
      | S.null set = error $ "UNDEFINED IN STACK\n" ++ show stack
      | otherwise  = set

----------------------------------------------------------------------------------------------------

argsOrderPred :: ArgsOrder -> Bool
argsOrderPred (ArgsOrder anns goal _) =
  all isJust anns &&
  (all (isJust . snd) . concatMap (concatMap getVars) $ goal)

----------------------------------------------------------------------------------------------------

disjPerm :: [G a] -> [[G a]]
disjPerm = (\(unifs, invs) -> (unifs ++) <$> permutations invs) . partition isUnif
  where
    isUnif :: G a -> Bool
    isUnif (_ :=: _) = True
    isUnif _         = False


disjStackPred :: Name -> ([G (S, Ann)], Stack) -> Bool
disjStackPred name (list, stD) = not $ isNoUndef list && isAllInvDef
  where
    isNoUndef :: [G (S, Ann)] -> Bool
    isNoUndef = all isJust . concatMap (fmap snd . getVars)

    isAllInvDef :: Bool
    isAllInvDef  = all isDefInv . filter isNotRecInvoke $ list

    isNotRecInvoke :: G a -> Bool
    isNotRecInvoke (Invoke name' _)
      | name == name' = False
      | otherwise     = True
    isNotRecInvoke _               = False

    isDefInv :: G a -> Bool
    isDefInv (Invoke name _) = maybe False (any argsOrderPred) $ M.lookup name stD
    isDefInv _               = error "isDefInv is undefined for not invoke goal"

----------------------------------------------------------------------------------------------------


{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}

module Syntax where

import Data.List
import Text.Printf

type X    = String -- Syntactic variables
type S    = Int    -- Semantic variables
type Name = String -- Names of variables/definitions

-- Terms
data Term v = V v
            | C String [Term v]
  deriving (Eq, Ord, Show)

type Tx     = Term X
type Ts     = Term S

instance Functor Term where
  fmap f (V v)    = V $ f v
  fmap f (C s ts) = C s $ map (fmap f) ts

-- Definitions
type Def = (Name, [Name], G X)

def :: Name -> [Name] -> G X -> Def
def = (,,)

-- Goals
data G a = Term a :=: Term a
         | G a :/\: G a
         | G a :\/: G a
         | Fresh  Name (G a)
         | Invoke Name [Term a]
         | Let Def (G a)
  deriving (Eq, Ord, Show)

freshVars :: [Name] -> G t -> ([Name], G t)
freshVars names (Fresh name goal) = freshVars (name : names) goal
freshVars names goal = (names, goal)

infix  8 :=:
infixr 7 :/\:
infixr 6 :\/:

infixr 7 &&&
infixr 6 |||
infix  8 ===

(===) :: Term a -> Term a -> G a
(===) = (:=:)

(|||) :: G a -> G a -> G a
(|||) = (:\/:)

(&&&) :: G a -> G a -> G a
(&&&) = (:/\:)


fresh :: [Name] -> G a -> G a
fresh xs g = foldr Fresh g xs

call :: Name -> [Term a] -> G a
call = Invoke

-- Free variables
fv :: Eq v => Term v -> [v]
fv t = nub $ fv' t where
  fv' (V v)    = [v]
  fv' (C _ ts) = concatMap fv' ts

fvg :: G X -> [X]
fvg = nub . fv'
  where
    fv' (t1 :=:  t2) = fv t1 ++ fv t2
    fv' (g1 :/\: g2) = fv' g1 ++ fv' g2
    fv' (g1 :\/: g2) = fv' g1 ++ fv' g2
    fv' (Invoke _ ts) = concatMap fv ts
    fv' (Fresh x g)   = fv' g \\ [x]
    fv' (Let (_, _, _) g) = fv' g


-- pretty print
--instance Show a => Show (Term a) where
--  show (V v) = printf "v.%s" (show v)
--  show (C name ts) =
--    case name of
--      "Nil" -> "[]"
--      "Cons" -> let [h,t] = ts
--                in printf "%s : %s" (show h) (show t)
--      x | (x == "s" || x == "S") && length ts == 1 -> printf "S(%s)" (show $ head ts)
--      x | (x == "o" || x == "O") && null ts -> "O"
--      _ -> case ts of
--             [] -> name
--             _  -> printf "C %s [%s]" name (unwords $ map show ts)
--
--instance Show a => Show (G a) where
--  show (t1 :=:  t2)               = printf "%s = %s" (show t1) (show t2)
--  show (g1 :/\: g2)               = printf "(%s /\\ %s)" (show g1) (show g2)
--  show (g1 :\/: g2)               = printf "(%s \\/ %s)" (show g1) (show g2)
--  show (Fresh name g)             =
--    let (names, goal) = freshVars [name] g in
--    printf "fresh %s (%s)" (show $ reverse names) (show goal)
--  show (Invoke name ts)           = printf "%s(%s)" name (show ts)
--  show (Let (name, args, body) g) = printf "let %s %s = %s in %s" name (unwords args) (show body) (show g)

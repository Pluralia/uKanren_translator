module Main (
      main
    ) where

import           Control.Monad        ((>=>))
import qualified Data.Map.Strict as M
import           Data.Maybe           (fromMaybe)
import           Data.List            (nub, union, intercalate)
import qualified Data.Set as S
import           Syntax

import           Annotation           (translate, PreAnn(..))
import           Parser               (defsAsts)

import           Program.Prop

-----------------------------------------------------------------------------------------------------

instance Show Program where
  show (Program defs goal) = unlines ["Program:", show goal, show defs]

-----------------------------------------------------------------------------------------------------

defsByNames :: M.Map Name Def -> [Name] -> [Def]
defsByNames nameToDef =
  fmap (\name -> fromMaybe (error $ "no func: " ++ name) $ M.lookup name nameToDef)


createProgram :: M.Map Name Def -> Name -> [Name] -> Program
createProgram nameToDef name args =
  let goal = makeFresh name args in Program (defsByGoal [] goal) goal
  where
    makeFresh :: Name -> [Name] -> G X
    makeFresh name args = fresh args $ Invoke name (V <$> args)

    defsByGoal :: [Def] -> G X -> [Def]
    defsByGoal knownDefs goal =
      let defs       = nub . defsByNames nameToDef . namesOfInvokes $ goal
          newDefs    = filter (`notElem` knownDefs) defs
       in defs `union` concatMap (\(Def _ _ goal) -> defsByGoal defs goal) newDefs
    
    namesOfInvokes :: G X -> [Name]
    namesOfInvokes (_ :=: _)       = []
    namesOfInvokes (g1 :/\: g2)    = namesOfInvokes g1 ++ namesOfInvokes g2
    namesOfInvokes (g1 :\/: g2)    = namesOfInvokes g1 ++ namesOfInvokes g2
    namesOfInvokes (Fresh _ g)     = namesOfInvokes g
    namesOfInvokes (Invoke name _) = [name]
    namesOfInvokes (Let _ _)       = error "LET"

initDefsByNames :: IO (M.Map Name Def)
initDefsByNames = do
  let
      inDirName = "resources/"
      inFileNames = (inDirName ++) <$> ["list", "num", "bool", "programs", "extra"]
  listListDefs <- mapM
                    (\fileName -> do
                        input <- readFile fileName
                        return . defsAsts $ input
                    )
                    inFileNames
  return . M.fromList . fmap (\def@(Def name _ _) -> (name, def)) . concat $ listListDefs

-----------------------------------------------------------------------------------------------------

main :: IO ()
main = do
  nameToDef <- initDefsByNames
{-
  -- print all defs by splitByStructure
  mapM_
    (print . defsByNames nameToDef)
    splitByStructure
-}

{-
  putStrLn "=====================================================================================\n\n"
  let appendoProgram = createProgram nameToDef "appendo" ["x", "y", "xy"]
  print appendoProgram
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate appendoProgram [("x", In), ("y", In)]
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate appendoProgram [("xy", In)]
  putStrLn "=====================================================================================\n\n"
-}

{-
  putStrLn "=====================================================================================\n\n"
  let appendoCtorsUnifProgram = createProgram nameToDef "appendoCtorsUnif" ["x", "y", "xy"]
  print appendoCtorsUnifProgram
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate appendoCtorsUnifProgram [("x", In), ("y", In)]
  putStrLn "-------------------------------------------------------------------------------------\n\n"
--  print $ translate appendoCtorsUnifProgram [("xy", In)]
  putStrLn "=====================================================================================\n\n"
-}

{-
  putStrLn "=====================================================================================\n\n"
  let reversoProgram = createProgram nameToDef "reverso" ["x", "y"]
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print reversoProgram
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate reversoProgram [("x", In)]
  putStrLn "-------------------------------------------------------------------------------------\n\n"
--  print $ translate reversoProgram [("y", In)]
  putStrLn "=====================================================================================\n\n"
-}

{-
  putStrLn "=====================================================================================\n\n"
  let reversoRevProgram = createProgram nameToDef "reversoRev" ["x", "y"]
  print reversoRevProgram
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate reversoRevProgram [("x", In)]
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate reversoRevProgram [("y", In)]
  putStrLn "=====================================================================================\n\n"
-}

{-
  putStrLn "=====================================================================================\n\n"
  let revaccoProgram = createProgram nameToDef "revacco" ["xs", "acc", "sx"]
  print revaccoProgram
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate revaccoProgram [("xs", In), ("acc", In)]
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate revaccoProgram [("sx", In)]
  putStrLn "=====================================================================================\n\n"
-}

{-
  putStrLn "=====================================================================================\n\n"
  let lengthoProgram = createProgram nameToDef "lengtho" ["x", "l"]
  print lengthoProgram
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate lengthoProgram [("x", In)]
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate lengthoProgram [("l", In)]
  putStrLn "=====================================================================================\n\n"
-}

{-
  putStrLn "=====================================================================================\n\n"
  let maxLengthoProgram = createProgram nameToDef "maxLengtho" ["x", "m", "l"]
  print maxLengthoProgram
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate maxLengthoProgram [("x", In), ("m", In)]
  putStrLn "-------------------------------------------------------------------------------------\n\n"
--  print $ translate maxLengthoProgram [("l", In)]
  putStrLn "=====================================================================================\n\n"
-}

  putStrLn "=====================================================================================\n\n"
  let plainEvaloProgram = plainQuery'
  print plainEvaloProgram
  putStrLn "-------------------------------------------------------------------------------------\n\n"
  print $ translate plainEvaloProgram [("res", In)]
  putStrLn "=====================================================================================\n\n"

-----------------------------------------------------------------------------------------------------

splitByStructure :: [[Name]]
splitByStructure = concat $ [
                     [fresh, unfresh]
                   , [dnf, undnf]
                   , [call, uncall]
                   ]
  where
    fresh, unfresh :: [Name]
    fresh   = [
                -- bool
                "oro", "ando"
                -- list
              , "appendo", "listo", "membero", "copy", "copy2", "lengtho", "maxo1", "reverso", "revacco"
                -- num
              , "notZero", "addo", "mulo", "leo", "gto"
                -- programs
              , "doubleAppendo", "singletonReverso", "isNum", "genLists", "has5", "eveno", "test", "go"
              ]
    unfresh = [
                -- bool
                "nando", "noto"
                -- list
              , "inBotho", "nilo", "singletono", "maxLengtho", "copy2", "copycopy", "maxo"
                -- num
              , "geo", "lto"
                -- programs
              , "palindromo", "doubleo", "emptyAppendo", "appendo123", "appendoXyz", "is5", "check5", "checkList5", "checkList51", "makeX", "makeY", "makeA", "makeB"
              ]

    dnf, undnf :: [Name]
    dnf   = [
              -- bool
              "nando", "noto", "oro", "ando"
              -- list
            , "appendo", "listo", "inBotho", "nilo", "singletono", "maxLengtho", "copy", "copy2", "copycopy", "lengtho", "maxo1", "maxo", "reverso", "revacco"
              -- num
            , "notZero", "addo", "mulo", "leo", "gto", "geo", "lto"
              -- programs
            , "doubleAppendo", "singletonReverso", "isNum", "genLists", "has5", "eveno", "test", "go", "palindromo", "doubleo", "emptyAppendo", "appendo123", "appendoXyz", "is5", "check5", "checkList5", "checkList51", "makeX", "makeY", "makeA", "makeB"
            ]
    undnf = [
              -- list
              "membero"
            ]

    call, uncall :: [Name]
    call   = [
               -- bool
               "noto", "oro", "ando"
               -- list
             , "appendo", "listo", "membero", "inBotho", "maxLengtho", "copy", "copy2", "copycopy", "lengtho", "maxo1", "maxo", "reverso", "revacco"
               -- num
             , "addo", "mulo", "leo", "gto", "geo", "lto"
               -- programs
             , "doubleAppendo", "singletonReverso", "genLists", "has5", "eveno", "test", "go", "palindromo", "doubleo", "emptyAppendo", "appendo123", "appendoXyz", "check5", "checkList5", "checkList51"
             ]
    uncall = [
               -- bool
               "nando"
               -- list
             , "nilo", "singletono" 
               -- num
             , "notZero"
               -- programs
             , "is5", "isNum", "makeX", "makeY", "makeA", "makeB"
             ]


-- there are calls but not recursive
-- no < self < cyclic: if no and self -> self
splitByRecursion :: [[Name]]
splitByRecursion = [no, self, cyclic]
  where
    no, self, cyclic :: [Name]
    no     = [
               -- bool
               "nando", "noto", "oro", "ando"
               -- list
             , "maxLengtho", "copycopy", "maxo"
               -- num
             , "geo", "lto"
               -- programs
             , "reverso", "doubleAppendo", "doubleo", "emptyAppendo", "appendo123", "appendoXyz", "singletonReverso", "check5", "checkList5", "checkList51", "eveno", "test", "go"
             ]
    self   = [
               -- list
               "appendo", "listo", "membero", "copy", "copy2", "lengtho", "maxo1", "reverso", "revacco"
               -- num
             , "addo", "mulo", "leo", "gto" 
               -- programs
             , "getLists", "has5"
             ]
    cyclic = [
             ]

{-
splitByInput :: [[Name]]
splitByInput = [predicate, function]
  where
    predicate, function :: [Name]
    predicate = [
               
                ]
    function  = [

                ]


splitByOutput :: [[Name]]
splitByOutput = [no, one, many]
  where
    no, one, many :: [Name]
    no   = [

           ]
    one  = [

           ]
    many = [

           ]
-}

-----------------------------------------------------------------------------------------------------

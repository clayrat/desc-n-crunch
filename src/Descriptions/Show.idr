module Descriptions.Show
import Descriptions.Core

%default total
%access export
%auto_implicits off

parenthesize : String -> String
parenthesize str = if length (words str) <= 1 then str else "(" ++ str ++ ")"

showLabel : TTName -> String
showLabel (UN n) with (strM n)
  showLabel (UN "")             | StrNil = ""
  showLabel (UN (strCons x xs)) | StrCons x xs =
    if isAlpha x then strCons x xs else "(" ++ strCons x xs ++ ")"
showLabel (NS n xs) = concat (intersperse "." (reverse xs)) ++ "." ++ showLabel n
showLabel (MN x y) = "{" ++ y ++ show x ++ "}"
showLabel (SN _) = "{{SN}}"

mutual
  gshowd : {e, Ix: _} -> (dr: TaggedDesc e Ix) -> (constraintsr: TaggedConstraints Show dr)
                      -> (d: Desc Ix) -> (constraints: Constraints Show d)
                      -> {ix: Ix} -> (synth: Synthesize d (TaggedData dr) ix)
                      -> String
  gshowd _  _            (Ret _) () Refl = ""
  gshowd dr constraintsr (Arg _ kdesc) (showa, showkdesc) (arg ** rest) =
    " " ++ parenthesize (show @{showa} arg)
        ++ gshowd dr constraintsr (kdesc arg) (showkdesc arg) rest
  gshowd dr constraintsr (Rec _ kdesc) constraints (rec ** rest) =
    " " ++ parenthesize (gshow dr constraintsr rec)
        ++ gshowd dr constraintsr kdesc constraints rest

  gshow : {e, Ix: _} -> (d: TaggedDesc e Ix) -> (constraints: TaggedConstraints Show d)
                    -> {ix : Ix} -> (X : TaggedData d ix) -> String
  gshow d constraints (Con (label ** tag ** rest)) =
    let constraints' = constraints label tag
        showrest = assert_total $ gshowd d constraints (d label tag) constraints' rest
    in showLabel label ++ showrest

module Descriptions.DecEq

import Helper
import Descriptions.Core as Core

%default total
%access export
%auto_implicits off

lemma_TagZnotS : {l,e:_} -> {t : Tag l e} -> Core.Z = Core.S t -> Void
lemma_TagZnotS Refl impossible

lemma_TagSInjective : {l,lr,e,er:_} -> {t : Tag l e} -> {t' : Tag lr er}
                     -> Core.S t = Core.S t' -> t = t'
lemma_TagSInjective Refl = Refl

using (l: CtorLabel, e: CtorEnum)
  implementation DecEq (Tag l e) where
    decEq  Z      Z    = Yes Refl
    decEq  Z     (S _) = No lemma_TagZnotS
    decEq (S _)   Z    = No (negEqSym lemma_TagZnotS)
    decEq (S t1) (S t2) with (decEq t1 t2)
      decEq (S t1) (S t1) | Yes Refl = Yes Refl
      decEq  _      _     | No contra = No (contra . lemma_TagSInjective)

lemma_DataConInjective : {x,y: _} -> Con x = Con y -> x = y
lemma_DataConInjective Refl = Refl

mutual
  gdecEqd : {e, Ix: _} -> (dr: TaggedDesc e Ix) -> (constraintsr: TaggedConstraints DecEq dr)
                       -> (d: Desc Ix) -> (constraints: Constraints DecEq d)
                       -> {ix: Ix} -> (synthX, synthY: Synthesize d (TaggedData dr) ix)
                       -> Dec (synthX = synthY)
  gdecEqd _ _ (Ret _) () Refl Refl = Yes Refl
  gdecEqd dr constraintsr (Arg _ kdesc) (decEqa, decEqkdesc) (arg1 ** rest1) (arg2 ** rest2)
   with (decEq @{decEqa} arg1 arg2)
    gdecEqd dr constraintsr (Arg _ kdesc) (_, decEqkdesc) (arg ** rest1) (arg ** rest2) | Yes Refl
     with (assert_total $ gdecEqd dr constraintsr (kdesc arg) (decEqkdesc arg) rest1 rest2)
      gdecEqd _ _ _ _ (arg ** rest) (arg ** rest) | Yes Refl | Yes Refl  = Yes Refl
      gdecEqd _ _ _ _ (arg ** _)    (arg ** _)    | Yes Refl | No contra = No (contra . dpairSndInjective)
    gdecEqd _ _ _ _ _ _ | No contra = No (contra . dpairFstInjective)
  gdecEqd dr constraintsr (Rec _ kdesc) decEqkdesc (rec1 ** rest1) (rec2 ** rest2)
   with (assert_total $ gdecEq dr constraintsr rec1 rec2)
    gdecEqd dr constraintsr (Rec _ kdesc) decEqkdesc (rec ** rest1) (rec ** rest2) | Yes Refl
     with (assert_total $ gdecEqd dr constraintsr kdesc decEqkdesc rest1 rest2)
      gdecEqd _ _ _ _ (rec ** rest) (rec ** rest) | Yes Refl | Yes Refl  = Yes Refl
      gdecEqd _ _ _ _ (rec ** _)    (rec ** _)    | Yes Refl | No contra = No (contra . dpairSndInjective)
    gdecEqd _ _ _ _ _ _ | No contra = No (contra . dpairFstInjective)

  gdecEq : {e, Ix: _} -> (d: TaggedDesc e Ix) -> (constraints: TaggedConstraints DecEq d)
                      -> {ix : Ix} -> (X, Y : TaggedData d ix) -> Dec (X = Y)
  gdecEq d constraints (Con dtx) (Con dty) with (gdecEqd d constraints (Untag d) (%implementation, \l => (%implementation, \t => constraints l t)) dtx dty)
    gdecEq _ _ (Con dt) (Con dt) | Yes Refl  = Yes Refl
    gdecEq _ _ (Con _)  (Con _)  | No contra = No (contra . lemma_DataConInjective)

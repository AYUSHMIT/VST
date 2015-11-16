Require Import Recdef.
Require Import floyd.proofauto.
Local Open Scope logic.
Require Import List. Import ListNotations.
Require Import general_lemmas.

Require Import split_array_lemmas.
Require Import ZArith. 
Require Import tweetNaclBase.
Require Import Salsa20.
Require Import verif_salsa_base.
Require Import tweetnaclVerifiableC.
Require Import Snuffle.
Require Import spec_salsa.  

Require Import verif_fcore_jbody. 
Opaque Snuffle.Snuffle. Opaque core_spec. Opaque fcore_result.
Opaque crypto_core_salsa20_spec. Opaque crypto_core_hsalsa20_spec.

Fixpoint WcontI (xs: list int) (j:nat) (l:list val):Prop :=
   match j with O => Zlength l = 16
   | (S n) => Zlength l = 16 /\
              exists t0 t1 t2 t3,
              Znth ((5 * (Z.of_nat n) + 4 * 0) mod 16) (map Vint xs) Vundef = Vint t0 /\
              Znth ((5 * (Z.of_nat n) + 4 * 1) mod 16) (map Vint xs) Vundef = Vint t1 /\
              Znth ((5 * (Z.of_nat n) + 4 * 2) mod 16) (map Vint xs) Vundef = Vint t2 /\
              Znth ((5 * (Z.of_nat n) + 4 * 3) mod 16) (map Vint xs) Vundef = Vint t3 /\
              exists wl, WcontI xs n wl /\
                match Wcopyspec t0 t1 t2 t3 with
                 (s0,s1,s2,s3) => wlistJ' wl (Z.of_nat n) s0 s1 s2 s3 l
                end
  end.

Lemma WcontI_Zlength xs j l: WcontI xs j l -> Zlength l=16.
Proof. intros. destruct j; eapply H. Qed. 

Lemma WWI r w (W: WcontI r 4 w) (R:Zlength r = 16): 
      exists wi, w=map Vint wi /\ snuffleRound r = Some wi.
Proof.
apply listD16 in R. 
destruct R as [x0 [x1 [x2 [x3 [x4 [x5 [x6 [x7 
              [x8 [x9 [x10 [x11 [x12 [x13 [x14 [x15 XX]]]]]]]]]]]]]]]]. subst r. 
destruct W as [HW H1]. 
destruct H1 as [t0 [t1 [t2 [t3 [T0 [T1 [T2 [T3 [w1 [[_ H1] W1]]]]]]]]]]. simpl in T0, T1, T2, T3.
rewrite Z.mod_small in T0. 2: omega.
rewrite Zmod_eq in T1. 2: omega. 
rewrite Zmod_eq in T2. 2: omega. 
rewrite Zmod_eq in T3. 2: omega. simpl in T0, T1, T2, T3. 
destruct H1 as [t4 [t5 [t6 [t7 [T4 [T5 [T6 [T7 [w2 [[_ H1] W2]]]]]]]]]]. simpl in T4, T5, T6, T7.
rewrite Zmod_eq in T4. 2: omega. 
rewrite Zmod_eq in T5. 2: omega.
rewrite Zmod_eq in T6. 2: omega.
rewrite Zmod_eq in T7. 2: omega. simpl in T4, T5, T6, T7.
destruct H1 as [t8 [t9 [t10 [t11 [T8 [T9 [T10 [T11 [w3 [[_ H1] W3]]]]]]]]]]. simpl in T8, T9, T10, T11.
rewrite Z.mod_small in T8. 2: omega.
rewrite Z.mod_small in T9. 2: omega.
rewrite Zmod_eq in T10. 2: omega.
rewrite Zmod_eq in T11. 2: omega. simpl in T8, T9, T10, T11.
destruct H1 as [t12 [t13 [t14 [t15 [T12 [T13 [T14 [T15 [w4 [L4 W4]]]]]]]]]]. simpl in T12, T13, T14, T15.
rewrite Z.mod_small in T12. 2: omega.
rewrite Z.mod_small in T13. 2: omega.
rewrite Z.mod_small in T14. 2: omega.
rewrite Z.mod_small in T15. 2: omega.
unfold Znth in *. simpl in  T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15.
symmetry in T0; inv T0. symmetry in T1; inv T1. symmetry in T2; inv T2. symmetry in T3; inv T3.
symmetry in T4; inv T4. symmetry in T5; inv T5. symmetry in T6; inv T6. symmetry in T7; inv T7.
symmetry in T8; inv T8. symmetry in T9; inv T9. symmetry in T10; inv T10. symmetry in T11; inv T11.
symmetry in T12; inv T12. symmetry in T13; inv T13. symmetry in T14; inv T14. symmetry in T15; inv T15.
red in L4.
simpl in W4.
remember (Int.xor x4 (Int.rol (Int.add x0 x12) (Int.repr 7))) as z1.
remember (Int.xor x8 (Int.rol (Int.add z1 x0) (Int.repr 9))) as z2.
remember (Int.xor x12 (Int.rol (Int.add z2 z1) (Int.repr 13))) as z3.
remember (Int.xor x0 (Int.rol (Int.add z3 z2) (Int.repr 18))) as z0.
apply listD16 in L4. 
destruct L4 as [y0 [y1 [y2 [y3 [y4 [y5 [y6 [y7 
               [y8 [y9 [y10 [y11 [y12 [y13 [y14 [y15 XX]]]]]]]]]]]]]]]]. subst w4.
destruct W4 as [_ W4]; simpl in W4. 
(*rewrite Z.mod_small in W4. 2: omega. 
rewrite Z.mod_small in W4. 2: omega. 
rewrite Z.mod_small in W4. 2: omega. 
rewrite Z.mod_small in W4. 2: omega.*)
unfold upd_Znth_in_list, sublist in W4; simpl in W4. subst w3. 
simpl in W3.
remember (Int.xor x9 (Int.rol (Int.add x5 x1) (Int.repr 7))) as z6.
remember (Int.xor x13 (Int.rol (Int.add z6 x5) (Int.repr 9))) as z7.
remember (Int.xor x1 (Int.rol (Int.add z7 z6) (Int.repr 13))) as z4.
remember (Int.xor x5 (Int.rol (Int.add z4 z7) (Int.repr 18))) as z5. 
destruct W3 as [_ W3]; simpl in W3. 
unfold upd_Znth_in_list, sublist in W3; simpl in W3. subst w2. 
destruct W2 as [_ W2]. simpl in W2. 
remember (Int.xor x14 (Int.rol (Int.add x10 x6) (Int.repr 7))) as z11.
remember (Int.xor x2 (Int.rol (Int.add z11 x10) (Int.repr 9))) as z8.
remember (Int.xor x6 (Int.rol (Int.add z8 z11) (Int.repr 13))) as z9.
remember (Int.xor x10 (Int.rol (Int.add z9 z8) (Int.repr 18))) as z10. 
unfold upd_Znth_in_list, sublist in W2; simpl in W2. subst w1. 
destruct W1 as [_ W1]; simpl in W1. 
remember (Int.xor x3 (Int.rol (Int.add x15 x11) (Int.repr 7))) as z12.
remember (Int.xor x7 (Int.rol (Int.add z12 x15) (Int.repr 9))) as z13.
remember (Int.xor x11 (Int.rol (Int.add z13 z12) (Int.repr 13))) as z14.
remember (Int.xor x15 (Int.rol (Int.add z14 z13) (Int.repr 18))) as z15.
unfold upd_Znth_in_list, sublist in W1; simpl in W1. subst w. clear HW. 
exists [z0; z1; z2; z3; z4; z5; z6; z7;
        z8; z9; z10; z11; z12; z13; z14; z15].
split. reflexivity.
rewrite Int.add_commut in Heqz0, Heqz2, Heqz3, Heqz4, Heqz5, Heqz7, Heqz8,
  Heqz9, Heqz10, Heqz13, Heqz14, Heqz15.
subst z0 z1 z2 z3 z4 z5 z6 z7 z8 z9 z10 z11 z12 z13 z14 z15. reflexivity.
Qed.

Lemma f_core_loop3: forall (Espec : OracleKind)
c k h nonce out w x y t OUT (xI:list int)
(data : SixteenByte * SixteenByte * (SixteenByte * SixteenByte)),
@semax CompSpecs Espec
  (initialized_list [_i] (func_tycontext f_core SalsaVarSpecs SalsaFunSpecs))
  (PROP  ()
   LOCAL  (temp _i (Vint (Int.repr 16)); lvar _t (tarray tuint 4) t;
   lvar _y (tarray tuint 16) y; lvar _x (tarray tuint 16) x;
   lvar _w (tarray tuint 16) w; temp _in nonce; temp _out out; temp _c c;
   temp _k k; temp _h (Vint (Int.repr h)))
   SEP  (data_at Tsh (tarray tuint 16) (map Vint xI) y;
   data_at Tsh (tarray tuint 16) (map Vint xI) x;
   data_at_ Tsh (tarray tuint 4) t; data_at_ Tsh (tarray tuint 16) w;
   CoreInSEP data (nonce, c, k);
   data_at Tsh (tarray tuchar 64) OUT out))
  (Sfor (Sset _i (Econst_int (Int.repr 0) tint))
     (Ebinop Olt (Etempvar _i tint) (Econst_int (Int.repr 20) tint) tint)
     (Ssequence
        (Sfor (Sset _j (Econst_int (Int.repr 0) tint))
           (Ebinop Olt (Etempvar _j tint) (Econst_int (Int.repr 4) tint) tint)
           (Ssequence
              (Sfor (Sset _m (Econst_int (Int.repr 0) tint))
                 (Ebinop Olt (Etempvar _m tint)
                    (Econst_int (Int.repr 4) tint) tint)
                 (Ssequence
                    (Sset _index
                       (Ebinop Omod
                          (Ebinop Oadd
                             (Ebinop Omul (Econst_int (Int.repr 5) tint)
                                (Etempvar _j tint) tint)
                             (Ebinop Omul (Econst_int (Int.repr 4) tint)
                                (Etempvar _m tint) tint) tint)
                          (Econst_int (Int.repr 16) tint) tint))
                    (Ssequence
                       (Sset _aux
                          (Ederef
                             (Ebinop Oadd (Evar _x (tarray tuint 16))
                                (Etempvar _index tint) (tptr tuint)) tuint))
                       (Sassign
                          (Ederef
                             (Ebinop Oadd (Evar _t (tarray tuint 4))
                                (Etempvar _m tint) (tptr tuint)) tuint)
                          (Etempvar _aux tuint))))
                 (Sset _m
                    (Ebinop Oadd (Etempvar _m tint)
                       (Econst_int (Int.repr 1) tint) tint)))
              (Ssequence
                 (Ssequence
                    (Sset _aux
                       (Ederef
                          (Ebinop Oadd (Evar _t (tarray tuint 4))
                             (Econst_int (Int.repr 0) tint) (tptr tuint))
                          tuint))
                    (Ssequence
                       (Sset _aux1
                          (Ederef
                             (Ebinop Oadd (Evar _t (tarray tuint 4))
                                (Econst_int (Int.repr 3) tint) (tptr tuint))
                             tuint))
                       (Ssequence
                          (Sset _aux
                             (Ebinop Oadd (Etempvar _aux tuint)
                                (Etempvar _aux1 tuint) tuint))
                          (Ssequence
                             (Ssequence
                                (Scall (Some 181%positive)
                                   (Evar _L32
                                      (Tfunction
                                         (Tcons tuint (Tcons tint Tnil))
                                         tuint cc_default))
                                   [Etempvar _aux tuint;
                                   Econst_int (Int.repr 7) tint])
                                (Sset _aux (Etempvar 181%positive tuint)))
                             (Ssequence
                                (Sset _aux1
                                   (Ederef
                                      (Ebinop Oadd (Evar _t (tarray tuint 4))
                                         (Econst_int (Int.repr 1) tint)
                                         (tptr tuint)) tuint))
                                (Ssequence
                                   (Sset _aux1
                                      (Ebinop Oxor (Etempvar _aux1 tuint)
                                         (Etempvar _aux tuint) tuint))
                                   (Sassign
                                      (Ederef
                                         (Ebinop Oadd
                                            (Evar _t (tarray tuint 4))
                                            (Econst_int (Int.repr 1) tint)
                                            (tptr tuint)) tuint)
                                      (Etempvar _aux1 tuint))))))))
                 (Ssequence
                    (Ssequence
                       (Sset _aux
                          (Ederef
                             (Ebinop Oadd (Evar _t (tarray tuint 4))
                                (Econst_int (Int.repr 1) tint) (tptr tuint))
                             tuint))
                       (Ssequence
                          (Sset _aux1
                             (Ederef
                                (Ebinop Oadd (Evar _t (tarray tuint 4))
                                   (Econst_int (Int.repr 0) tint)
                                   (tptr tuint)) tuint))
                          (Ssequence
                             (Sset _aux
                                (Ebinop Oadd (Etempvar _aux tuint)
                                   (Etempvar _aux1 tuint) tuint))
                             (Ssequence
                                (Ssequence
                                   (Scall (Some 182%positive)
                                      (Evar _L32
                                         (Tfunction
                                            (Tcons tuint (Tcons tint Tnil))
                                            tuint cc_default))
                                      [Etempvar _aux tuint;
                                      Econst_int (Int.repr 9) tint])
                                   (Sset _aux (Etempvar 182%positive tuint)))
                                (Ssequence
                                   (Sset _aux1
                                      (Ederef
                                         (Ebinop Oadd
                                            (Evar _t (tarray tuint 4))
                                            (Econst_int (Int.repr 2) tint)
                                            (tptr tuint)) tuint))
                                   (Ssequence
                                      (Sset _aux1
                                         (Ebinop Oxor (Etempvar _aux1 tuint)
                                            (Etempvar _aux tuint) tuint))
                                      (Sassign
                                         (Ederef
                                            (Ebinop Oadd
                                               (Evar _t (tarray tuint 4))
                                               (Econst_int (Int.repr 2) tint)
                                               (tptr tuint)) tuint)
                                         (Etempvar _aux1 tuint))))))))
                    (Ssequence
                       (Ssequence
                          (Sset _aux
                             (Ederef
                                (Ebinop Oadd (Evar _t (tarray tuint 4))
                                   (Econst_int (Int.repr 2) tint)
                                   (tptr tuint)) tuint))
                          (Ssequence
                             (Sset _aux1
                                (Ederef
                                   (Ebinop Oadd (Evar _t (tarray tuint 4))
                                      (Econst_int (Int.repr 1) tint)
                                      (tptr tuint)) tuint))
                             (Ssequence
                                (Sset _aux
                                   (Ebinop Oadd (Etempvar _aux tuint)
                                      (Etempvar _aux1 tuint) tuint))
                                (Ssequence
                                   (Ssequence
                                      (Scall (Some 183%positive)
                                         (Evar _L32
                                            (Tfunction
                                               (Tcons tuint (Tcons tint Tnil))
                                               tuint cc_default))
                                         [Etempvar _aux tuint;
                                         Econst_int (Int.repr 13) tint])
                                      (Sset _aux
                                         (Etempvar 183%positive tuint)))
                                   (Ssequence
                                      (Sset _aux1
                                         (Ederef
                                            (Ebinop Oadd
                                               (Evar _t (tarray tuint 4))
                                               (Econst_int (Int.repr 3) tint)
                                               (tptr tuint)) tuint))
                                      (Ssequence
                                         (Sset _aux1
                                            (Ebinop Oxor
                                               (Etempvar _aux1 tuint)
                                               (Etempvar _aux tuint) tuint))
                                         (Sassign
                                            (Ederef
                                               (Ebinop Oadd
                                                  (Evar _t (tarray tuint 4))
                                                  (Econst_int (Int.repr 3)
                                                     tint) (tptr tuint))
                                               tuint) (Etempvar _aux1 tuint))))))))
                       (Ssequence
                          (Ssequence
                             (Sset _aux
                                (Ederef
                                   (Ebinop Oadd (Evar _t (tarray tuint 4))
                                      (Econst_int (Int.repr 3) tint)
                                      (tptr tuint)) tuint))
                             (Ssequence
                                (Sset _aux1
                                   (Ederef
                                      (Ebinop Oadd (Evar _t (tarray tuint 4))
                                         (Econst_int (Int.repr 2) tint)
                                         (tptr tuint)) tuint))
                                (Ssequence
                                   (Sset _aux
                                      (Ebinop Oadd (Etempvar _aux tuint)
                                         (Etempvar _aux1 tuint) tuint))
                                   (Ssequence
                                      (Ssequence
                                         (Scall (Some 184%positive)
                                            (Evar _L32
                                               (Tfunction
                                                  (Tcons tuint
                                                     (Tcons tint Tnil)) tuint
                                                  cc_default))
                                            [Etempvar _aux tuint;
                                            Econst_int (Int.repr 18) tint])
                                         (Sset _aux
                                            (Etempvar 184%positive tuint)))
                                      (Ssequence
                                         (Sset _aux1
                                            (Ederef
                                               (Ebinop Oadd
                                                  (Evar _t (tarray tuint 4))
                                                  (Econst_int (Int.repr 0)
                                                     tint) (tptr tuint))
                                               tuint))
                                         (Ssequence
                                            (Sset _aux1
                                               (Ebinop Oxor
                                                  (Etempvar _aux1 tuint)
                                                  (Etempvar _aux tuint) tuint))
                                            (Sassign
                                               (Ederef
                                                  (Ebinop Oadd
                                                     (Evar _t
                                                        (tarray tuint 4))
                                                     (Econst_int (Int.repr 0)
                                                        tint) (tptr tuint))
                                                  tuint)
                                               (Etempvar _aux1 tuint))))))))
                          (Sfor (Sset _m (Econst_int (Int.repr 0) tint))
                             (Ebinop Olt (Etempvar _m tint)
                                (Econst_int (Int.repr 4) tint) tint)
                             (Ssequence
                                (Sset _aux
                                   (Ederef
                                      (Ebinop Oadd (Evar _t (tarray tuint 4))
                                         (Etempvar _m tint) (tptr tuint))
                                      tuint))
                                (Ssequence
                                   (Sset _aux1
                                      (Ebinop Oadd
                                         (Ebinop Omul
                                            (Econst_int (Int.repr 4) tint)
                                            (Etempvar _j tint) tint)
                                         (Ebinop Omod
                                            (Ebinop Oadd (Etempvar _j tint)
                                               (Etempvar _m tint) tint)
                                            (Econst_int (Int.repr 4) tint)
                                            tint) tint))
                                   (Sassign
                                      (Ederef
                                         (Ebinop Oadd
                                            (Evar _w (tarray tuint 16))
                                            (Etempvar _aux1 tuint)
                                            (tptr tuint)) tuint)
                                      (Etempvar _aux tuint))))
                             (Sset _m
                                (Ebinop Oadd (Etempvar _m tint)
                                   (Econst_int (Int.repr 1) tint) tint))))))))
           (Sset _j
              (Ebinop Oadd (Etempvar _j tint) (Econst_int (Int.repr 1) tint)
                 tint)))
        (Sfor (Sset _m (Econst_int (Int.repr 0) tint))
           (Ebinop Olt (Etempvar _m tint) (Econst_int (Int.repr 16) tint)
              tint)
           (Ssequence
              (Sset _aux
                 (Ederef
                    (Ebinop Oadd (Evar _w (tarray tuint 16))
                       (Etempvar _m tint) (tptr tuint)) tuint))
              (Sassign
                 (Ederef
                    (Ebinop Oadd (Evar _x (tarray tuint 16))
                       (Etempvar _m tint) (tptr tuint)) tuint)
                 (Etempvar _aux tuint)))
           (Sset _m
              (Ebinop Oadd (Etempvar _m tint) (Econst_int (Int.repr 1) tint)
                 tint))))
     (Sset _i
        (Ebinop Oadd (Etempvar _i tint) (Econst_int (Int.repr 1) tint) tint)))
  (normal_ret_assert
  (PROP  ()
   LOCAL  (temp _i (Vint (Int.repr 20)); lvar _t (tarray tuint 4) t; lvar _y (tarray tuint 16) y;
   lvar _x (tarray tuint 16) x; lvar _w (tarray tuint 16) w; temp _in nonce;
   temp _out out; temp _c c; temp _k k; temp _h (Vint (Int.repr h)))
   SEP 
   (EX r:_, !!(Snuffle 20 xI = Some r) && data_at Tsh (tarray tuint 16) (map Vint r) x;
   data_at Tsh (tarray tuint 16) (map Vint xI) y;
   data_at_ Tsh (tarray tuint 4) t; data_at_ Tsh (tarray tuint 16) w;
   CoreInSEP data (nonce, c, k); 
   data_at Tsh (tarray tuchar 64) OUT out))).
Proof. intros. abbreviate_semax.
Time assert_PROP (Zlength (map Vint xI) = 16) as XIZ by entailer!. (*5.1*)
rewrite Zlength_map in XIZ.
Opaque Zplus. Opaque Z.mul. Opaque mult. Opaque plus.
Opaque Z.sub. Opaque Snuffle.
drop_LOCAL 0%nat. 
Time forward_for_simple_bound 20 (EX i:Z, 
  (PROP  ()
   LOCAL  (lvar _t (tarray tuint 4) t;
   lvar _y (tarray tuint 16) y; lvar _x (tarray tuint 16) x;
   lvar _w (tarray tuint 16) w; temp _in nonce; temp _out out; temp _c c;
   temp _k k; temp _h (Vint (Int.repr h)))
   SEP  (data_at Tsh (tarray tuint 16) (map Vint xI) y;
   EX r:_, !!(Snuffle (Z.to_nat i) xI = Some r) && data_at Tsh (tarray tuint 16) (map Vint r) x;
   data_at_ Tsh (tarray tuint 4) t; data_at_ Tsh (tarray tuint 16) w;
   CoreInSEP data (nonce, c, k); data_at Tsh (tarray tuchar 64) OUT out))). (*3.6*)
{ Exists xI. Time entailer!. (*7.1*) } 

(*Issue: why doesn't this work if we move it to the end of the proof of this lemma, 
  after the other subgoal has been proven?*)
Focus 2. Time entailer!. (*5.4*) Intros r. Exists r. Time entailer!. (*0.7*)

{ rename H into I. Intros r. rename H into R. 
  assert (XI: length xI = 16%nat). eapply (Zlength_length _ _ 16). omega. trivial.
  assert (RL:= Snuffle_length _ _ _ R XI).
  assert (RZL: Zlength r = 16). rewrite Zlength_correct, RL; reflexivity.
            
  Time forward_for_simple_bound 4 (EX j:Z,
  (PROP  ()
   LOCAL  (temp _i (Vint (Int.repr i)); lvar _t (tarray tuint 4) t;
   lvar _y (tarray tuint 16) y; lvar _x (tarray tuint 16) x;
   lvar _w (tarray tuint 16) w; temp _in nonce; temp _out out; temp _c c;
   temp _k k; temp _h (Vint (Int.repr h)))
   SEP  (data_at Tsh (tarray tuint 16) (map Vint r) x;
   data_at Tsh (tarray tuint 16) (map Vint xI) y;
   data_at_ Tsh (tarray tuint 4) t; 
   EX l:_, !!(WcontI r (Z.to_nat j) l) && data_at Tsh (tarray tuint 16) l w;
   CoreInSEP data (nonce, c, k);
   data_at Tsh (tarray tuchar 64) OUT out))). (*5.1*)
  { Exists (list_repeat 16 Vundef). Time entailer!. (*9.2*) apply derives_refl. }
  { rename H into J. rename i0 into j.
    Intros wlist. rename H into WCONT.
    destruct (Znth_mapVint r ((5 * j + 4 * 0) mod 16) Vundef) as [t0 T0].
      rewrite RZL; apply Z_mod_lt; omega.
    destruct (Znth_mapVint r ((5 * j + 4 * 1) mod 16) Vundef) as [t1 T1].
      rewrite RZL; apply Z_mod_lt; omega.
    destruct (Znth_mapVint r ((5 * j + 4 * 2) mod 16) Vundef) as [t2 T2].
      rewrite RZL; apply Z_mod_lt; omega.
    destruct (Znth_mapVint r ((5 * j + 4 * 3) mod 16) Vundef) as [t3 T3].
      rewrite RZL; apply Z_mod_lt; omega.
    eapply semax_pre_post.
    Focus 3. apply (Jbody _ c k h nonce out w x y t (map Vint xI) i j OUT data) with (wlist0:=wlist); trivial; try eassumption.
    Time entailer!. (*11.5*)
    intros; apply andp_left2. unfold POSTCONDITION, abbreviate.
    apply assert_lemmas.normal_ret_assert_derives'.
    Intros W. Exists W. Time entailer!. (*12.5*) 
    rewrite Z.add_comm, Z2Nat.inj_add; try omega.
    assert (X: (Z.to_nat 1 + Z.to_nat j = S (Z.to_nat j))%nat) by reflexivity.
    rewrite X. simpl. split. assumption. 
    exists t0, t1, t2, t3. rewrite Z2Nat.id, T0, T1, T2, T3.
    split. trivial. split. trivial. split. trivial. split. trivial.
    exists wlist. split; trivial. omega. }

  Intros wlist. rename H into HW.
  destruct (WWI _ _ HW RZL) as [wints [WI SNUFF]]. subst wlist.
(*  assert (WL: Zlength wlist = 16) by apply WLIST.
  destruct (WcontI_4I _ _ WLIST RZL) as [wints WW]. subst wlist.*)
  eapply semax_pre_post.
  Focus 3. apply (array_copy3 _ c k h nonce out OUT data)
            with (i0:=i)(w0:=w)(x0:=x)(y0:=y)(t0:=t)
                 (ys:=map Vint xI)(xlist:=map Vint r)(wlist:=map Vint wints); trivial.
           intros. apply Znth_mapVint. 
              destruct (snuffleRound_length _ _ SNUFF) as [WL _].
              rewrite Zlength_correct, WL; simpl; omega.
  apply andp_left2. Time entailer!. (*8.6*)
  intros ? ?. apply andp_left2.
    unfold POSTCONDITION, abbreviate.
    apply assert_lemmas.normal_ret_assert_derives'. Time entailer!. (*11.4*)
  rewrite Z.add_comm, Z2Nat.inj_add; try omega.
  Transparent Snuffle. Transparent plus.
  Exists wints. simpl. rewrite R. Time entailer!. (*0.7*) }
Time Qed. (*23.6*)
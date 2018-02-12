Require Import VST.floyd.proofauto.
Require Import VST.progs.strlib.
Require Import VST.progs.strings.
Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.

Definition strchr_spec :=
 DECLARE _strchr
  WITH str : val, s : String.string, c : Z
  PRE  [ _str OF tptr tschar, _c OF tint ]
    PROP (Byte.min_signed <= c <= Byte.max_signed; c <> 0)
    LOCAL (temp _str str; temp _c (Vint (Int.repr c)))
    SEP (cstring s str)
  POST [ tptr tschar ]
   EX r : val,
    PROP (let ls := string_to_Z s in 
          (exists i, Znth i ls 0 = c /\ Forall (fun d => d<>c) (sublist 0 i ls)
                     /\ r = offset_val i str)
       \/ (Forall (fun d => d<>c) ls /\ r = nullval))
    LOCAL (temp ret_temp r)
    SEP (cstring s str).

Definition strcat_spec :=
 DECLARE _strcat
  WITH dest : val, sd : String.string, n : Z, src : val, ss : String.string
  PRE  [ _dest OF tptr tschar, _src OF tptr tschar ]
    PROP (Zlength (string_to_Z sd) + Zlength (string_to_Z ss) < n)
    LOCAL (temp _dest dest; temp _src src)
    SEP (cstringn sd n dest; cstring ss src)
  POST [ tptr tschar ]
    PROP ()
    LOCAL (temp ret_temp dest)
    SEP (cstringn (String.append sd ss) n dest; cstring ss src).

Definition strcmp_spec :=
 DECLARE _strcmp
  WITH str1 : val, s1 : String.string, str2 : val, s2 : String.string
  PRE [ _str1 OF tptr tschar, _str2 OF tptr tschar ]
    PROP ()
    LOCAL (temp _str1 str1; temp _str2 str2)
    SEP (cstring s1 str1; cstring s2 str2)
  POST [ tint ]
   EX i : int,
    PROP (if Int.eq i Int.zero then s1 = s2 else s1 <> s2)
    LOCAL (temp ret_temp (Vint i))
    SEP (cstring s1 str1; cstring s2 str2).

Definition strcpy_spec :=
 DECLARE _strcpy
  WITH dest : val, n : Z, src : val, s : String.string
  PRE [ _dest OF tptr tschar, _src OF tptr tschar ]
    PROP (Zlength (string_to_Z s) < n)
    LOCAL (temp _dest dest; temp _src src)
    SEP (data_at_ Tsh (tarray tschar n) dest; cstring s src)
  POST [ tptr tschar ]
    PROP ()
    LOCAL (temp ret_temp dest)
    SEP (cstringn s n dest; cstring s src).

Definition Gprog : funspecs :=
         ltac:(with_library prog [ strchr_spec; strcat_spec; strcmp_spec ]).

(* up *)
(* Often an if statement only serves to add information (e.g., rule out some cases). *)
Ltac forward_if_prop P := match goal with |-semax _ (PROP () ?Q) _ _ => forward_if (PROP (P) Q) end.

Lemma insert_PROP:
 forall (P: Prop) (L: list Prop) Q, P -> PROPx L Q = PROPx (P::L) Q.
Proof.
intros.
unfold PROPx.
f_equal. f_equal. simpl. apply prop_ext. intuition.
Qed.

Ltac revert_PROP :=
 match goal with 
 | H: ?P |- ENTAIL _, PROPx ?L ?Q |-- _ =>
    match type of P with Prop => 
      rewrite (insert_PROP P L Q) by apply H; clear H
    end
 end.

Hint Rewrite Z.add_simpl_r Z.sub_simpl_r : norm.

Lemma body_strchr': semax_body Vprog Gprog f_strchr strchr_spec.
  (* Alternate proof of strchar to demonstrate handling
    of "continue:" using an evar.  Not very easy... *)
Proof.
start_function.
forward.
unfold cstring.
set (ls := string_to_Z s) in *.
Intros.
evar (Q: Z -> environ->mpred).
forward_loop (EX i : Z,
  PROP (0 <= i < Zlength ls + 1; Forall (fun d => d <> c) (sublist 0 i ls))
  LOCAL (temp _str str; temp _c (Vint (Int.repr c)); temp _i (Vint (Int.repr i)))
  SEP (data_at Tsh (tarray tschar (Zlength ls + 1))
          (map Vint (map Int.repr (ls ++ [0]))) str))
 continue: (EX i:Z, Q i).
  Exists 0; rewrite sublist_nil; entailer!.
- Intros i. 
  pose proof (repable_string_i s i) as Hi; fold ls in Hi.
  forward.
  assert (Zlength (ls ++ [0]) = Zlength ls + 1) by (autorewrite with sublist; auto).
  forward.
  forward.
  simpl cast_int_int. rewrite sign_ext_char by auto.
  forward_if_prop (Znth i (ls ++ [0]) 0 <> c).
  { rewrite data_at_isptr; Intros.
    forward. 
    Exists (offset_val i str).
    unfold cstring. fold ls. 
    entailer!.
    left. exists i. split3; auto.
    destruct (zlt i (Zlength ls)); autorewrite with sublist in *; simpl in *; auto.
    assert (i = Zlength ls) by omega. subst i.
    rewrite Z.sub_diag in *. contradiction H0. reflexivity. }
  { forward.
    entailer!. }
  Intros.
  forward_if_prop (Znth i (ls ++ [0]) 0 <> 0).
  { rewrite data_at_isptr; Intros.
    forward.
    Exists (Vint Int.zero); unfold cstring; rewrite !map_app; entailer!.
    right. split; auto.
    assert (i = Zlength ls). {
      destruct (zlt i (Zlength ls)); [ | omega].
      contradiction H1. rewrite app_Znth1 in H6 by omega.
      rewrite <- H6. apply Znth_In. omega.
    }
    subst i.
    autorewrite with sublist in H3; auto. }
  { forward.
    entailer!. }
  subst Q. Exists i. repeat revert_PROP. apply ENTAIL_refl.
-
  subst Q. cbv beta.
  Intros i.
  deadvars!.
  forward.
  Exists (i+1).
  entailer!.
  assert (i <> Zlength ls)
     by(intro; subst i; apply H7; autorewrite with sublist; reflexivity).
  split. rep_omega.
  rewrite (sublist_split 0 i) by rep_omega. rewrite Forall_app. split; auto.
  rewrite sublist_len_1 with (d:=0) by rep_omega. repeat constructor.
  rewrite app_Znth1 in H6 by rep_omega. auto.
Qed.

Lemma body_strchr: semax_body Vprog Gprog f_strchr strchr_spec.
Proof.
start_function.
forward.
unfold cstring in *.
set (ls := string_to_Z s) in *.
Intros.
forward_loop (EX i : Z,
  PROP (0 <= i < Zlength ls + 1; Forall (fun d => d <> c) (sublist 0 i ls))
  LOCAL (temp _str str; temp _c (Vint (Int.repr c)); temp _i (Vint (Int.repr i)))
  SEP (data_at Tsh (tarray tschar (Zlength ls + 1))
          (map Vint (map Int.repr (ls ++ [0]))) str))
 continue: (EX i : Z,
  PROP (0 <= i < Zlength ls + 1; Forall (fun d => d <> c) (sublist 0 i ls))
  LOCAL (temp _str str; temp _c (Vint (Int.repr c)); temp _i (Vint (Int.repr (i-1))))
  SEP (data_at Tsh (tarray tschar (Zlength ls + 1))
          (map Vint (map Int.repr (ls ++ [0]))) str)).
  Exists 0; rewrite sublist_nil; entailer!.
- Intros i. 
  pose proof (repable_string_i s i) as Hi; fold ls in Hi.
  forward.
  assert (Zlength (ls ++ [0]) = Zlength ls + 1) by (autorewrite with sublist; auto).
  forward.
  forward.
  simpl cast_int_int. rewrite sign_ext_char by auto.
  forward_if_prop (Znth i (ls ++ [0]) 0 <> c).
  { forward. 
    Exists (offset_val i str).
    entailer!.
    left. exists i. split3; auto. rewrite app_Znth1; auto.
    destruct (zlt i (Zlength ls)); auto. rewrite app_Znth2 in H0 by list_solve.
    replace (i - Zlength ls) with 0 in H0 by omega. contradiction H0; reflexivity. }
  { forward.
    entailer!. }
  Intros.
  forward_if.
  { forward.
    Exists nullval; rewrite !map_app; entailer!.
    right. split; auto.
    assert (i = Zlength ls). {
      destruct (zlt i (Zlength ls)); [ | omega].
      contradiction H1. rewrite app_Znth1 in H6 by omega.
      rewrite <- H6. apply Znth_In. omega.
    }
    subst i.
    autorewrite with sublist in H3; auto. }
  forward.
  Exists (i+1); entailer!.
  assert (i <> Zlength ls) 
     by(intro; subst i; apply H6; autorewrite with sublist; reflexivity).
  split.
  rep_omega. 
  rewrite (sublist_split 0 i) by rep_omega. rewrite Forall_app. split; auto.
  rewrite sublist_len_1 with (d:=0) by rep_omega. repeat constructor.
  rewrite app_Znth1 in H5 by rep_omega. auto.
-
  Intros i.
  forward.
 Exists i.
 entailer!.
Qed.

Lemma split_data_at_app:
 forall sh t n (al bl: list (reptype t)) abl'
         (al': reptype (tarray t (Zlength al)))
         (bl': reptype (tarray t (n - Zlength al)))
          p ,
   n = Zlength (al++bl) ->
   JMeq abl' (al++bl) ->
   JMeq al' al ->
   JMeq bl' bl ->
   data_at sh (tarray t n) abl' p = 
         data_at sh (tarray t (Zlength al)) al' p
        * data_at sh (tarray t (n - Zlength al)) bl'
                 (field_address0 (tarray t n) [ArraySubsc (Zlength al)] p).
Proof.
intros.
unfold tarray.
erewrite split2_data_at_Tarray.
3: rewrite sublist_same; [eassumption | auto | auto ].
3: rewrite sublist_app1.
3: rewrite sublist_same; [eassumption | auto | auto ].
5: rewrite sublist_app2.
5: rewrite sublist_same; [eassumption | auto | auto ].
auto.
all: rewrite Zlength_app in H; rep_omega.
Qed.

Lemma split_data_at_app_tschar:
 forall sh n (al bl: list val) p ,
   n = Zlength (al++bl) ->
   data_at sh (tarray tschar n) (al++bl) p = 
         data_at sh (tarray tschar (Zlength al)) al p
        * data_at sh (tarray tschar (n - Zlength al)) bl
                 (field_address0 (tarray tschar n) [ArraySubsc (Zlength al)] p).
Proof.
intros.
apply (split_data_at_app sh tschar n al bl (al++bl)); auto.
Qed.

Lemma body_strcat: semax_body Vprog Gprog f_strcat strcat_spec.
Proof.
start_function.
unfold cstringn, cstring in *.
Intros.
assert_PROP (n <= Ptrofs.max_unsigned) as Hn. {
   entailer!.
   clear - H H2. destruct H2 as [? [_ [? _]]]. destruct dest; try contradiction; simpl in *.
   rewrite Z.max_r in * by rep_omega. rep_omega.
}
set (ld := string_to_Z sd) in *.
set (ls := string_to_Z ss) in *.
forward.
forward_loop (EX i : Z,
    PROP (0 <= i < Zlength ld + 1)
    LOCAL (temp _i (Vint (Int.repr i)); temp _dest dest; temp _src src)
    SEP (data_at Tsh (tarray tschar n)
          (map Vint (map Int.repr (ld ++ [0])) ++
           list_repeat (Z.to_nat (n - (Zlength ld + 1))) Vundef) dest;
   data_at Tsh (tarray tschar (Zlength ls + 1))
     (map Vint (map Int.repr (ls ++ [0]))) src))
 continue: (EX i : Z,
    PROP (0 <= i < Zlength ld + 1)
    LOCAL (temp _i (Vint (Int.repr (i-1))); temp _dest dest; temp _src src)
    SEP (data_at Tsh (tarray tschar n)
          (map Vint (map Int.repr (ld ++ [0])) ++
           list_repeat (Z.to_nat (n - (Zlength ld + 1))) Vundef) dest;
   data_at Tsh (tarray tschar (Zlength ls + 1))
     (map Vint (map Int.repr (ls ++ [0]))) src))
  break: (PROP ( )
   LOCAL (temp _i (Vint (Int.repr (Zlength ld))); temp _dest dest; 
   temp _src src)
   SEP (data_at Tsh (tarray tschar n)
          (map Vint (map Int.repr (ld ++ [0])) ++
           list_repeat (Z.to_nat (n - (Zlength ld + 1))) Vundef) dest;
   data_at Tsh (tarray tschar (Zlength ls + 1))
     (map Vint (map Int.repr (ls ++ [0]))) src)).
-
  Exists 0; entailer!.
-
  Intros i.
  forward.
  pose proof (repable_string_i sd i) as Hi; fold ld in Hi.
  forward.
  { entailer!. }
  { entailer!.
    autorewrite with sublist. 
    rewrite Znth_map with (d':= Int.zero) by list_solve.
    rewrite Znth_map with (d':= 0) by list_solve.
    simpl. normalize. }
  autorewrite with sublist; simpl.
  forward.
    rewrite Znth_map with (d':= Int.zero) by list_solve.
    rewrite Znth_map with (d':= 0) by list_solve.
   simpl.
  rewrite sign_ext_char by auto.
  forward_if.
  + forward.
    entailer!. f_equal. f_equal.
    destruct (zlt i (Zlength ld)); [ | rep_omega].
    rewrite app_Znth1 in H3 by rep_omega. contradiction H0.
    rewrite <- H3; apply Znth_In; omega.
  +
    forward.
    Exists (i+1); entailer!.
    destruct (zlt i (Zlength ld)); [ rep_omega | ].
    assert (i = Zlength ld) by omega. subst i.
    subst; rewrite app_Znth2, Zminus_diag in * by omega; contradiction.
- Intros i.
   forward.
   Exists i. entailer!. 
-
  abbreviate_semax.
  forward.
  forward_loop (EX j : Z,
    PROP (0 <= j < Zlength ls + 1)
    LOCAL (temp _j (Vint (Int.repr j)); temp _i (Vint (Int.repr (Zlength ld)));
           temp _dest dest; temp _src src)
    SEP (data_at Tsh (tarray tschar n)
          (map Vint (map Int.repr (ld ++ sublist 0 j ls)) ++
           list_repeat (Z.to_nat (n - (Zlength ld + j))) Vundef) dest;
         data_at Tsh (tarray tschar (Zlength ls + 1))
           (map Vint (map Int.repr (ls ++ [0]))) src))
   continue: (EX j : Z,
    PROP (0 <= j < Zlength ls + 1)
    LOCAL (temp _j (Vint (Int.repr (j-1))); temp _i (Vint (Int.repr (Zlength ld)));
           temp _dest dest; temp _src src)
    SEP (data_at Tsh (tarray tschar n)
          (map Vint (map Int.repr (ld ++ sublist 0 j ls)) ++
           list_repeat (Z.to_nat (n - (Zlength ld + j))) Vundef) dest;
         data_at Tsh (tarray tschar (Zlength ls + 1))
           (map Vint (map Int.repr (ls ++ [0]))) src)).
  { Exists 0; entailer!.  autorewrite with sublist.
    rewrite !map_app. rewrite <- app_assoc.
    rewrite split_data_at_app_tschar by list_solve.
    rewrite (split_data_at_app_tschar _ n) by list_solve.
    autorewrite with sublist.
    cancel.    
   }
  { Intros j.
  forward.
  assert (Zlength (ls ++ [0]) = Zlength ls + 1) by (autorewrite with sublist; auto).
  pose proof (repable_string_i ss j) as Hj; fold ls in Hj.
  forward.
  forward.
  forward.
  entailer!.
  clear H3.
  simpl.
  rewrite sign_ext_char by auto.
  rewrite upd_Znth_app2 by list_solve.
  autorewrite with sublist.
  forward_if.
  + forward.
      clear H8 H9 H6 PNdest PNsrc.
      rewrite string_to_Z_app; autorewrite with sublist. fold ld. fold ls.
      rewrite prop_true_andp 
        by (intro Hx; apply in_app in Hx; destruct Hx; contradiction).
      cancel.
    destruct (zlt j (Zlength ls)).
         rewrite app_Znth1 in H3 by rep_omega. contradiction H1; rewrite <- H3; apply Znth_In; omega.
    assert (j = Zlength ls) by omega; subst.
    autorewrite with sublist.
 apply derives_refl'.
 unfold data_at; f_equal. 
 replace (n - (Zlength ld + Zlength ls))
   with (1 + (n - (Zlength ld + Zlength ls+1))) by rep_omega.
 rewrite <- list_repeat_app' by rep_omega.
 rewrite upd_Znth_app1 by list_solve.
 rewrite app_assoc.
 simpl.
 rewrite !map_app.
 reflexivity.
 +
  forward.
  Exists (j+1).
  destruct (zlt j (Zlength ls)).
   2:  assert (j = Zlength ls) by omega; subst j;
        rewrite app_Znth2 in H3 by omega; rewrite Z.sub_diag in H3; contradiction H3; reflexivity.
  entailer!.
  change (field_at Tsh (tarray tschar n) []) with (data_at Tsh (tarray tschar n)).
   rewrite (sublist_split 0 j (j+1)) by rep_omega.
   rewrite (app_assoc ld). rewrite !map_app.
   set (lds :=map Vint (map Int.repr ld) ++map Vint (map Int.repr (sublist 0 j ls))).
   rewrite <- app_assoc.
   rewrite (split_data_at_app_tschar _ n) by (subst lds; list_solve).
   rewrite (split_data_at_app_tschar _ n) by (subst lds; list_solve).
 replace (n - (Zlength ld + j))
   with (1 + (n - (Zlength ld + (j + 1)))) by rep_omega.
 rewrite <- list_repeat_app' by rep_omega.
  cancel.
  rewrite upd_Znth_app1 by (autorewrite with sublist; rep_omega).
  rewrite app_Znth1 by list_solve.
  rewrite sublist_len_1 with (d:=0) by rep_omega.
  change (upd_Znth 0 (list_repeat (Z.to_nat 1) Vundef)
     (Vint (Int.repr (Znth j ls 0))))  with (map Vint (map Int.repr [Znth j ls 0])).
  cancel.
  }
 + Intros j. forward. Exists j. entailer!.
Qed.

Lemma body_strcmp: semax_body Vprog Gprog f_strcmp strcmp_spec.
Proof.
start_function.
unfold cstring in *.
set (ls1 := string_to_Z s1).
set (ls2 := string_to_Z s2).
forward.
Intros.
forward_loop (EX i : Z,
  PROP (0 <= i < Zlength ls1 + 1; 0 <= i < Zlength ls2 + 1;
        sublist 0 i ls1 = sublist 0 i ls2)
  LOCAL (temp _str1 str1; temp _str2 str2; temp _i (Vint (Int.repr i)))
  SEP (data_at Tsh (tarray tschar (Zlength ls1 + 1))
          (map Vint (map Int.repr (ls1 ++ [0]))) str1;
       data_at Tsh (tarray tschar (Zlength ls2 + 1))
          (map Vint (map Int.repr (ls2 ++ [0]))) str2))
  continue: (EX i : Z,
  PROP (0 <= i < Zlength ls1 + 1; 0 <= i < Zlength ls2 + 1;
        sublist 0 i ls1 = sublist 0 i ls2)
  LOCAL (temp _str1 str1; temp _str2 str2; temp _i (Vint (Int.repr (i-1))))
  SEP (data_at Tsh (tarray tschar (Zlength ls1 + 1))
          (map Vint (map Int.repr (ls1 ++ [0]))) str1;
       data_at Tsh (tarray tschar (Zlength ls2 + 1))
          (map Vint (map Int.repr (ls2 ++ [0]))) str2)).
- Exists 0; entailer!.
- Intros i.
  pose proof (repable_string_i s1 i) as Hi1; fold ls1 in Hi1.
  pose proof (repable_string_i s2 i) as Hi2; fold ls2 in Hi2.
  forward.
  assert (Zlength (ls1 ++ [0]) = Zlength ls1 + 1) by (autorewrite with sublist; auto).
  forward.
  assert (Zlength (ls2 ++ [0]) = Zlength ls2 + 1) by (autorewrite with sublist; auto).
  forward.
  simpl.
  rewrite !sign_ext_char by auto.
  assert (Znth i (ls1 ++ [0]) 0 = 0 <-> i = Zlength ls1) as Hs1.
  { split; [|intro; subst; rewrite app_Znth2, Zminus_diag by omega; auto].
    destruct (zlt i (Zlength ls1)); [|omega].
    intro X; lapply (Znth_In i ls1 0); [|omega].
    rewrite app_Znth1 in X by auto; rewrite X; contradiction. }
  assert (Znth i (ls2 ++ [0]) 0 = 0 <-> i = Zlength ls2) as Hs2.
  { split; [|intro; subst; rewrite app_Znth2, Zminus_diag by omega; auto].
    destruct (zlt i (Zlength ls2)); [|omega].
    intro X; lapply (Znth_In i ls2 0); [|omega].
    rewrite app_Znth1 in X by auto; rewrite X; contradiction. }
  forward.
  forward.
  match goal with |-semax _ (PROP () (LOCALx ?Q ?R)) _ _ =>
    forward_if (PROP ()
      (LOCALx (temp _t'1 (Val.of_bool (Z.eqb i (Zlength ls1) && Z.eqb i (Zlength ls2))) :: Q) R)) end.
  { forward.
    simpl force_val. rewrite sign_ext_char by auto. 
    rewrite Hs1 in *.
    destruct (zeq (Znth i (ls2 ++ [0]) 0) 0).
    + rewrite e; simpl force_val.
         assert (i = Zlength ls2). {
           destruct (zlt i (Zlength ls2)); [ | omega].
           rewrite app_Znth1 in e by list_solve.
           contradiction H0; rewrite <- e; apply Znth_In; list_solve.
        }
        rewrite  (proj2 Hs1 H6).
     rewrite (proj2 (Z.eqb_eq i (Zlength ls1)) H6).
     rewrite (proj2 (Z.eqb_eq i (Zlength ls2)) H7).
     entailer!.
  +
    rewrite Int.eq_false.
     rewrite (proj2 (Z.eqb_eq i (Zlength ls1)) H6).
     rewrite Hs2 in n.
     rewrite (proj2 (Z.eqb_neq i (Zlength ls2))) by auto.
    entailer!.
     contradict n.
     apply repr_inj_signed; auto; red; rep_omega.
 }
  { forward.
    entailer!.
    destruct (i =? Zlength ls1) eqn: Heq; auto.
    rewrite Z.eqb_eq in Heq; tauto. }
  forward_if.
 +
  rewrite andb_true_iff in H6; destruct H6.
  rewrite Z.eqb_eq in H6,H7.
  forward.
  Exists (Int.repr 0).
  entailer!. simpl.
  autorewrite with sublist in H3. subst ls1 ls2.
  apply string_to_Z_inj; auto.
 +
  rewrite H6.
  rewrite andb_false_iff in H6. rewrite !Z.eqb_neq in H6.
  forward_if.
  *
    forward. Exists (Int.repr (-1)). entailer!.
    simpl. intro; subst. assert (ls1=ls2) by reflexivity. rewrite <- H17 in *. clear H17 ls2.
     assert (Hlt1: i < Zlength ls1) by omega.
     rewrite (app_Znth1 _ _ [0] 0 _ Hlt1) in *.
    rewrite sign_ext_char in H7 by auto.
    rewrite Int.signed_repr in H7 by rep_omega.
    clear - H7; omega.
 *
   forward_if.
   forward.
   Exists (Int.repr 1). entailer!. simpl. intro. subst s2.
   assert (ls1=ls2) by reflexivity. rewrite <- H18 in *. clear H18 ls2.
   assert (Hlt1: i < Zlength ls1) by omega.
   rewrite (app_Znth1 _ _ [0] 0 _ Hlt1) in *.
    rewrite sign_ext_char in H8 by auto.
    rewrite Int.signed_repr in H8 by rep_omega.
    clear - H8; omega.

   forward.
   Exists (i+1).
   entailer!.
    rewrite sign_ext_char in * by auto.
    rewrite Int.signed_repr in H7 by rep_omega.
    rewrite Int.signed_repr in H8 by rep_omega.
   assert (Znth i (ls1 ++ [0]) 0 = Znth i (ls2 ++ [0]) 0) by omega.
   clear H7 H8.
   clear H13 H14 H16 H17 H12 H15 PNstr1 PNstr2.
   clear H10 H11 H9.
   destruct (zlt i (Zlength ls1)).
  Focus 2. {
         rewrite app_Znth2 in Hs1 by rep_omega.
         destruct (zeq i (Zlength ls1)); [ | omega].
         subst.
         destruct H6; [congruence | ].
         assert (Zlength ls1 < Zlength ls2) by omega.
         rewrite app_Znth2 in H18 by rep_omega.
         rewrite app_Znth1 in H18 by rep_omega.
         rewrite Z.sub_diag in H18. contradiction H0.
         change (Znth 0 [0] 0) with 0 in H18. rewrite H18.
         apply Znth_In. omega.
   } Unfocus.
  destruct (zlt i (Zlength ls2)).
  Focus 2. {
         rewrite app_Znth2 in Hs1 by rep_omega.
         destruct (zeq i (Zlength ls2)); [ | omega].
         subst.
         destruct H6; [ | congruence].
         assert (Zlength ls1 > Zlength ls2) by omega.
         rewrite app_Znth1 in H18 by rep_omega.
         rewrite app_Znth2 in H18 by rep_omega.
         rewrite Z.sub_diag in H18. contradiction H.
         change (Znth 0 [0] 0) with 0 in H18. rewrite <- H18.
         apply Znth_In. omega.
   } Unfocus.
  split. omega. split. omega.
  rewrite (sublist_split 0 i (i+1)) by omega.
  rewrite (sublist_split 0 i (i+1)) by omega.
  f_equal; auto.
  rewrite !sublist_len_1 with (d:=0) by omega.
  rewrite !app_Znth1 in H18 by list_solve.
  f_equal. auto.
 -
  Intros i.
  forward.
  Exists i.
  entailer!.
Qed.

Lemma body_strcpy: semax_body Vprog Gprog f_strcpy strcpy_spec.
Proof.
start_function.
unfold cstring,cstringn in *.
set (ls := string_to_Z s) in *.
assert_PROP (n <= Ptrofs.max_unsigned) as Hn. {
   entailer!.
   clear - H H0. destruct H0 as [? [_ [? _]]]. destruct dest; try contradiction; simpl in *.
   rewrite Z.max_r in * by rep_omega. rep_omega.
}
forward.
Intros.
forward_loop (EX i : Z,
  PROP (0 <= i < Zlength ls + 1)
  LOCAL (temp _i (Vint (Int.repr i)); temp _dest dest; temp _src src)
  SEP (data_at Tsh (tarray tschar n)
        (map Vint (map Int.repr (sublist 0 i ls)) ++ list_repeat (Z.to_nat (n - i)) Vundef) dest;
       data_at Tsh (tarray tschar (Zlength ls + 1)) (map Vint (map Int.repr (ls ++ [0]))) src))
 continue: (EX i : Z,
  PROP (0 <= i < Zlength ls + 1)
  LOCAL (temp _i (Vint (Int.repr (i-1))); temp _dest dest; temp _src src)
  SEP (data_at Tsh (tarray tschar n)
        (map Vint (map Int.repr (sublist 0 i ls)) ++ list_repeat (Z.to_nat (n - i)) Vundef) dest;
       data_at Tsh (tarray tschar (Zlength ls + 1)) (map Vint (map Int.repr (ls ++ [0]))) src)).
*
 Exists 0. rewrite Z.sub_0_r; entailer!.
*
 Intros i.
 forward.
 assert (Zlength (ls ++ [0]) = Zlength ls + 1) by (autorewrite with sublist; auto).
 pose proof (repable_string_i s i) as Hi; fold ls in Hi.
 forward.
 forward.
 simpl.
 rewrite sign_ext_char by auto.
 forward.
 forward_if.
+ forward.
   entailer!.
  destruct (zlt i (Zlength ls)).
    {rewrite app_Znth1 in H3 by omega.
     contradiction H0. rewrite <- H3. apply Znth_In; omega. }
  assert (i = Zlength ls) by omega. subst i. clear g.
  change (field_at Tsh (tarray tschar n) []) with (data_at Tsh (tarray tschar n)).
  rewrite upd_Znth_app2 by list_solve.
  autorewrite with sublist.
  rewrite !map_app.
  rewrite <- app_assoc.
   rewrite (split_data_at_app_tschar _ n) by list_solve.
   rewrite (split_data_at_app_tschar _ n) by list_solve.
   autorewrite with sublist.
   replace (n - Zlength ls) with (1 + (n - (Zlength ls + 1))) at 2 by list_solve.
  rewrite <- list_repeat_app' by omega.
  rewrite upd_Znth_app1 by list_solve.
  rewrite !split_data_at_app_tschar by list_solve.
  cancel.
+
    destruct (zlt i (Zlength ls)).
   Focus 2. {
     rewrite app_Znth2 in H3 by omega.
     assert (i = Zlength ls) by omega; subst i. rewrite Z.sub_diag in H3.
     contradiction H3; reflexivity.
   } Unfocus.
  forward. Exists (i+1). entailer!. 
  autorewrite with sublist.
  rewrite upd_Znth_app2 by list_solve.
  rewrite (sublist_split 0 i (i+1)) by list_solve.
  rewrite !map_app. rewrite <- app_assoc.
  autorewrite with sublist.
  change (field_at Tsh (tarray tschar n) []) with (data_at Tsh (tarray tschar n)).
  rewrite !(split_data_at_app_tschar _ n) by list_solve.
  autorewrite with sublist.
   replace (n - i) with (1 + (n-(i+ 1))) at 2 by list_solve.
  rewrite <- list_repeat_app' by omega.
  rewrite upd_Znth_app1 by list_solve.
  cancel.
  rewrite !split_data_at_app_tschar by list_solve.
  autorewrite with sublist.
  rewrite sublist_len_1 with (d:=0) by omega.
  simpl. cancel.
*
  Intros i.
  forward.
  Exists i.
  entailer!.
Qed.


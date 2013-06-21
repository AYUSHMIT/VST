(*CompCert imports*)
Require Import compcert.common.Events.
Require Import compcert.common.Memory.
Require Import compcert.lib.Coqlib.
Require Import compcert.common.Values.
Require Import compcert.lib.Maps.
Require Import compcert.lib.Integers.
Require Import compcert.lib.Axioms.
Require Import common.Globalenvs.

Lemma mem_unchanged_on_sub: forall (P Q: block -> BinInt.Z -> Prop) m m',
  Mem.unchanged_on Q m m' -> 
  (forall b ofs, P b ofs -> Q b ofs) -> 
  Mem.unchanged_on P m m'.
Proof.
intros until m'; intros [H1 H2] H3.
split; intros.
solve[apply (H1 b ofs k p (H3 b ofs H)); auto].
solve[apply (H2 b ofs); auto]. 
Qed.

Lemma inject_separated_same_meminj: forall j m m', 
  Events.inject_separated j j m m'.
Proof. intros j m m' b; intros. congruence. Qed.

Theorem drop_extends:
  forall m1 m2 lo hi b p m1',
  Mem.extends m1 m2 ->
  Mem.drop_perm m1 b lo hi p = Some m1'  ->
  exists m2',
     Mem.drop_perm m2 b lo hi p = Some m2'
  /\ Mem.extends m1' m2'.
Proof.
  intros. inv H.
  destruct (Mem.drop_mapped_inj  _ _ _ b b 0 _ _ _ _ mext_inj H0) as [m2' [D Inj]].
        intros b'; intros. inv H1. inv H2. left. assumption.
         reflexivity.
  repeat rewrite Zplus_0_r in D. exists m2'. split; trivial.
  split; trivial.
  rewrite (Mem.nextblock_drop _ _ _ _ _ _ H0). 
  rewrite (Mem.nextblock_drop _ _ _ _ _ _ D). assumption.
Qed.  

Lemma mem_inj_id_trans: forall m1 m2 (Inj12: Mem.mem_inj inject_id m1 m2) m3 
          (Inj23: Mem.mem_inj inject_id m2 m3),Mem.mem_inj inject_id m1 m3.
Proof. intros.
  destruct Inj12. rename mi_perm into perm12. rename mi_access into access12. 
  rename mi_memval into memval12.
  destruct Inj23. rename mi_perm into perm23. rename mi_access into access23. 
  rename mi_memval into memval23.
  split; intros.
  (*mi_perm*)
  apply (perm12 _ _ _ _  _ _ H) in H0. 
  assert (inject_id b2 = Some (b2, delta)).
  unfold inject_id in *. inv H. trivial.
  apply (perm23 _ _ _ _  _ _ H1) in H0.  inv H. inv H1. rewrite Zplus_0_r in H0. 
  assumption.
  (*mi_access*)
  apply (access12 _ _ _ _  _ _ H) in H0. 
  assert (inject_id b2 = Some (b2, delta)).
  unfold inject_id in *. inv H. trivial.
  apply (access23 _ _ _ _  _ _ H1) in H0.  inv H. inv H1. rewrite Zplus_0_r in H0. 
  assumption.
  (*mi_memval*)
  assert (MV1:= memval12 _ _ _ _  H H0). 
  assert (inject_id b2 = Some (b2, delta)).
  unfold inject_id in *. inv H. trivial.
  assert (R2: Mem.perm m2 b2 ofs Cur Readable).
  apply (perm12 _ _ _ _  _ _ H) in H0. inv H. rewrite Zplus_0_r in H0. 
  assumption.
  assert (MV2:= memval23 _ _ _ _  H1 R2).
  inv H. inv H1.  rewrite Zplus_0_r in *.
  remember  (ZMap.get ofs (PMap.get b2 (Mem.mem_contents m2))) as v.
  destruct v. inv MV1. apply MV2.
  inv MV1. apply MV2.
  inv MV2. constructor.
  inv MV1. inv MV2. inv H3. inv H4. 
  rewrite Int.add_zero. rewrite Int.add_zero.  
  econstructor. reflexivity. 
  rewrite Int.add_zero. trivial.
  inv MV2. inv H3. rewrite Int.add_zero. 
  rewrite Int.add_zero in H5. econstructor.
Qed.

Lemma extends_trans: forall m1 m2 
  (Ext12: Mem.extends m1 m2) m3 (Ext23: Mem.extends m2 m3), Mem.extends m1 m3.
Proof. intros. inv Ext12. inv Ext23.
  split. rewrite mext_next. assumption. eapply mem_inj_id_trans; eauto. 
Qed.  

Lemma memval_inject_id_refl: forall v, memval_inject inject_id v v. 
Proof.  
destruct v. constructor. constructor. econstructor. reflexivity. 
rewrite Int.add_zero. trivial. 
Qed.

Lemma extends_refl: forall m, Mem.extends m m.
Proof. intros.
  split. trivial.
  split; intros. 
     inv H.  rewrite Zplus_0_r. assumption.
     inv H.  rewrite Zplus_0_r. assumption.
     inv H.  rewrite Zplus_0_r. apply memval_inject_id_refl.
Qed.

Lemma compose_meminj_idR: forall j, j = compose_meminj j inject_id.
Proof. intros. unfold  compose_meminj, inject_id. 
   apply extensionality. intro b. 
   remember (j b). 
   destruct o; trivial. destruct p. rewrite Zplus_0_r. trivial.
Qed.

Lemma compose_meminj_idL: forall j, j = compose_meminj inject_id j.
Proof. intros. unfold  compose_meminj, inject_id.
   apply extensionality. intro b.
   remember (j b). 
   destruct o; trivial. destruct p. rewrite Zplus_0_l. trivial.  
Qed.

Lemma perm_decE: 
  forall m b ofs k p PF,
  (Mem.perm_dec m b ofs k p = left PF <-> Mem.perm m b ofs k p).
Proof.
intros until p.
split; auto.
intros H1.
destruct (Mem.perm_dec m b ofs k p).
solve[f_equal; apply proof_irr].
solve[elimtype False; auto].
Qed.

Lemma extends_inject_compose:
  forall f m1 m2 m3,
  Mem.extends m1 m2 -> Mem.inject f m2 m3 -> Mem.inject f m1 m3.
Proof. 
  intros.
  inv H. inv mext_inj. inv H0. inv mi_inj.
  split; intros. 
  split; intros. 
  apply (mi_perm _ _ _ _ _ _ (eq_refl _)) in H0. rewrite Zplus_0_r in H0.
  apply (mi_perm0 _ _ _ _ _ _ H H0).
  apply (mi_access _ _ _ _ _ _ (eq_refl _)) in H0. rewrite Zplus_0_r in H0.
  apply (mi_access0 _ _ _ _ _ _ H H0).
  assert (K1:= mi_memval _ _ _ _ (eq_refl _) H0).
  apply  (mi_perm _ _ _ _ _ _ (eq_refl _)) in H0. rewrite Zplus_0_r in H0.
  assert (K2:= mi_memval0 _ _ _ _ H H0). rewrite Zplus_0_r in K1.
  assert (K:= memval_inject_compose _ _ _ _ _ K1 K2).
  rewrite <- compose_meminj_idL in K. apply K.
  apply mi_freeblocks. unfold Mem.valid_block. rewrite <- mext_next. apply H.
  eapply mi_mappedblocks. apply H.
  intros b; intros.  
  apply (mi_perm _ _ _ _ _ _ (eq_refl _)) in H2. 
  rewrite Zplus_0_r in H2. apply (mi_perm _ _ _ _ _ _ (eq_refl _)) in H3. 
  rewrite Zplus_0_r in H3.
  apply (mi_no_overlap _ _ _ _ _ _ _ _ H H0 H1 H2 H3).
  eapply mi_representable. apply H.
  unfold Mem.weak_valid_pointer in H0|-*.
(* apply orb_true_iff in H0; apply orb_true_iff.*)
 destruct H0; [left | right].
 unfold Mem.valid_pointer in H0|-*.
 apply (mi_perm b b 0 _ _ Nonempty (eq_refl _)) in H0.
 rewrite Zplus_0_r in H0.
 apply H0. 
 apply (mi_perm b b 0 _ _ Nonempty (eq_refl _)) in H0.
 rewrite Zplus_0_r in H0.
 apply H0. 
Qed.

Lemma inject_extends_compose:
  forall f m1 m2 m3,
  Mem.inject f m1 m2 -> Mem.extends m2 m3 -> Mem.inject f m1 m3.
Proof. intros.
  inv H. inv mi_inj. inv H0. inv mext_inj.
  split; intros. 
  split; intros. 
  apply (mi_perm _ _ _ _ _ _ H) in H0.
  apply (mi_perm0 _ _ _ _ _ _  (eq_refl _)) in H0.  rewrite Zplus_0_r in H0. 
   assumption.
  apply (mi_access _ _ _ _ _ _ H) in H0.
  apply (mi_access0 _ _ _ _ _ _  (eq_refl _)) in H0. rewrite Zplus_0_r in H0. 
   assumption.
  assert (K1:= mi_memval _ _ _ _ H H0).
  apply  (mi_perm _ _ _ _ _ _ H) in H0. 
  assert (K2:= mi_memval0 _ _ _ _ (eq_refl _) H0). rewrite Zplus_0_r in K2.
  assert (K:= memval_inject_compose _ _ _ _ _ K1 K2).
  rewrite <- compose_meminj_idR in K. apply K.
  apply mi_freeblocks. apply H.
  unfold Mem.valid_block. rewrite <- mext_next. eapply mi_mappedblocks. apply H.
  intros b; intros. apply (mi_no_overlap _ _ _ _ _ _ _ _ H H0 H1 H2 H3).
  eapply mi_representable. apply H. apply H0.
Qed.

Lemma extends_extends_compose:
  forall m1 m2 m3,
    Mem.extends m1 m2 -> Mem.extends m2 m3 -> Mem.extends m1 m3.
Proof. intros.
  inv H. inv mext_inj. inv H0. inv mext_inj.
  split; intros. rewrite mext_next; assumption. 
  split; intros.
  apply (mi_perm _ _ _ _ _ _ H) in H0. 
  apply (mi_perm0 _ _ _ _ _ _  (eq_refl _)) in H0. rewrite Zplus_0_r in H0. 
   assumption.
  apply (mi_access _ _ _ _ _ _ H) in H0.
  apply (mi_access0 _ _ _ _ _ _  (eq_refl _)) in H0. rewrite Zplus_0_r in H0. 
   assumption.
  assert (K1:= mi_memval _ _ _ _ H H0).
  apply  (mi_perm _ _ _ _ _ _ H) in H0. 
  assert (K2:= mi_memval0 _ _ _ _ (eq_refl _) H0). rewrite Zplus_0_r in K2.
  assert (K:= memval_inject_compose _ _ _ _ _ K1 K2).
  rewrite <- compose_meminj_idR in K. apply K.
Qed.

Lemma flatinj_E: forall b b1 b2 delta (H:Mem.flat_inj b b1 = Some (b2, delta)), 
  b2=b1 /\ delta=0 /\ Plt b2 b.
Proof. 
  unfold Mem.flat_inj. intros.
  destruct (plt b1 b); inv H. repeat split; trivial.
Qed.

Lemma flatinj_I: forall bb b, Plt b bb -> Mem.flat_inj bb b = Some (b, 0).
Proof. 
  intros. unfold Mem.flat_inj.
  destruct (plt b bb); trivial. exfalso. xomega. 
Qed.

Lemma flatinj_mono: forall b b1 b2 b' delta 
  (F: Mem.flat_inj b1 b = Some (b', delta)),
  Plt b1 b2 -> Mem.flat_inj b2 b = Some (b', delta).
Proof. intros.
  apply flatinj_E in F. destruct F as [? [? ?]]; subst.
  apply flatinj_I. xomega.
Qed.

(* A minimal preservation property we sometimes require.*)
Definition mem_forward (m1 m2:mem) :=
  (forall b, Mem.valid_block m1 b ->
    Mem.valid_block m2 b /\ 
    forall ofs p, Mem.perm m2 b ofs Max p -> Mem.perm m1 b ofs Max p).

Lemma mem_forward_refl: forall m, mem_forward m m.
Proof. intros m b H. split; eauto. Qed. 

Lemma mem_forward_trans: forall m1 m2 m3, 
  mem_forward m1 m2 -> mem_forward m2 m3 -> mem_forward m1 m3.
Proof. intros. intros  b Hb.
  destruct (H _ Hb). 
  destruct (H0 _ H1).
  split; eauto. 
Qed. 

Lemma forward_unchanged_trans: forall P m1 m2 m3,
Mem.unchanged_on P m1 m2 -> Mem.unchanged_on P m2 m3 ->
mem_forward m1 m2 -> mem_forward m2 m3 ->
mem_forward m1 m3 /\ Mem.unchanged_on P m1 m3.
Proof. intros.
split. eapply mem_forward_trans; eassumption.
split; intros.
  destruct H.
  destruct (unchanged_on_perm _ _ k p H3 H4).
  destruct H0. destruct (H1 _ H4).
  destruct (unchanged_on_perm0 _ _ k p H3 H0).
  split; intros; auto.
destruct H.
  rewrite <- (unchanged_on_contents _ _ H3 H4).
  destruct H0.
  apply (unchanged_on_contents0 _ _ H3). 
  apply unchanged_on_perm; try assumption.
  apply Mem.perm_valid_block in H4. assumption.
Qed. 

Lemma matchOptE: forall {A} (a:option A) (P: A -> Prop),
   match a with Some b => P b | None => False end -> 
   exists b, a = Some b /\ P b.
Proof. intros. destruct a; try contradiction. exists a; auto. Qed. 

Lemma compose_meminjD_None: forall j jj b, 
  (compose_meminj j jj) b = None -> 
  j b = None \/ 
  (exists b', exists ofs, j b = Some(b',ofs) /\ jj b' = None). 
Proof. 
  unfold compose_meminj; intros.
  destruct (j b).
  destruct p. right.
  remember (jj b0) as zz; destruct zz. destruct p. inv H.
  exists b0. exists z. rewrite <- Heqzz. auto.
  left; trivial.
Qed.

Lemma compose_meminjD_Some: forall j jj b b2 ofs2, 
       (compose_meminj j jj) b = Some(b2,ofs2) -> 
       exists b1, exists ofs1, exists ofs,
       j b = Some(b1,ofs1) /\ jj b1 = Some(b2,ofs) /\ ofs2=ofs1+ofs. 
Proof. unfold compose_meminj; intros.
       remember (j b) as z; destruct z; apply eq_sym in Heqz.
         destruct p. exists b0. exists z. 
         remember (jj b0) as zz. 
         destruct zz; apply eq_sym in Heqzz. 
           destruct p. inv H. exists z0. auto.
           inv H.
         inv H.
Qed. 

Lemma compose_meminj_inject_incr: forall j12 j12' j23 j23'
  (InjIncr12: inject_incr j12 j12') (InjIncr23: inject_incr j23 j23'),
  inject_incr (compose_meminj j12 j23) (compose_meminj j12' j23').
Proof.
  intros. intros b; intros. 
  apply compose_meminjD_Some in H. 
  destruct H as [b1 [ofs1 [ofs [Hb [Hb1 Hdelta]]]]]. 
  unfold compose_meminj.
  rewrite (InjIncr12 _ _ _ Hb).
  rewrite (InjIncr23 _ _ _ Hb1). subst. trivial.
Qed.

Lemma compose_meminj_inject_separated: forall j12 j12' j23 j23' m1 m2 m3
   (InjSep12 : inject_separated j12 j12' m1 m2)
   (InjSep23 : inject_separated j23 j23' m2 m3)
   (InjIncr12: inject_incr j12 j12') (InjIncr23: inject_incr j23 j23')
   (BV12: forall b1 b2 ofs, j12 b1 = Some (b2,ofs) -> Mem.valid_block m1 b1 /\ Mem.valid_block m2 b2)
   (BV23: forall b1 b2 ofs, j23 b1 = Some (b2,ofs) -> Mem.valid_block m2 b1 /\ Mem.valid_block m3 b2),
   inject_separated (compose_meminj j12 j23) (compose_meminj j12' j23') m1 m3.
Proof. intros.
  unfold compose_meminj; intros b; intros.
  remember (j12 b) as j12b.
  destruct j12b; inv H; apply eq_sym in Heqj12b. destruct p.
    rewrite (InjIncr12 _ _ _ Heqj12b) in H0.
    remember (j23 b0) as j23b0.
    destruct j23b0; inv H2; apply eq_sym in Heqj23b0. destruct p. inv H1.
    remember (j23' b0) as j23'b0.
    destruct j23'b0; inv H0; apply eq_sym in Heqj23'b0. destruct p. inv H1.
    destruct (InjSep23 _ _ _ Heqj23b0 Heqj23'b0).    
    split; trivial. exfalso. apply H. eapply BV12. apply Heqj12b.
  remember (j12' b) as j12'b.
  destruct j12'b; inv H0; apply eq_sym in Heqj12'b. destruct p.
    destruct (InjSep12 _ _ _ Heqj12b Heqj12'b). split; trivial.
    remember (j23' b0) as j23'b0.
    destruct j23'b0; inv H1; apply eq_sym in Heqj23'b0. destruct p. inv H3.
    remember (j23 b0) as j23b0.
    destruct j23b0; apply eq_sym in Heqj23b0. destruct p. rewrite (InjIncr23 _ _ _ Heqj23b0) in Heqj23'b0. inv Heqj23'b0.      
      exfalso. apply H0. eapply BV23. apply Heqj23b0.
    destruct (InjSep23 _ _ _ Heqj23b0 Heqj23'b0). assumption.    
Qed.

Lemma compose_meminj_inject_separated': forall j12 j12' j23 j23' m1 m2 m3
   (InjSep12 : inject_separated j12 j12' m1 m2)
   (InjSep23 : inject_separated j23 j23' m2 m3)
   (InjIncr12: inject_incr j12 j12') (InjIncr23: inject_incr j23 j23')
   (MInj12: Mem.inject j12 m1 m2)
   (MInj23: Mem.inject j23 m2 m3),
   inject_separated (compose_meminj j12 j23) (compose_meminj j12' j23') m1 m3.
Proof. intros.
  eapply compose_meminj_inject_separated; try eassumption.
  intros; split. apply (Mem.valid_block_inject_1 _ _ _ _ _ _ H MInj12). apply (Mem.valid_block_inject_2 _ _ _ _ _ _ H MInj12).
  intros; split. apply (Mem.valid_block_inject_1 _ _ _ _ _ _ H MInj23). apply (Mem.valid_block_inject_2 _ _ _ _ _ _ H MInj23).
Qed.

Lemma forall_lessdef_refl: forall vals,  Forall2 Val.lessdef vals vals.
Proof. induction vals; econstructor; trivial. Qed.

Lemma lessdef_hastype: forall v v' (V:Val.lessdef v v') T, 
              Val.has_type v' T -> Val.has_type v T.
Proof. intros. inv V; simpl; trivial. Qed.

Lemma forall_lessdef_hastype: forall vals vals' 
          (V:Forall2 Val.lessdef vals vals') Ts 
          (HTs: Forall2 Val.has_type vals' Ts),
          Forall2 Val.has_type vals Ts.
Proof.
  intros vals vals' V.
  induction V; simpl in *; intros.
       trivial.
  inv HTs. constructor. eapply  lessdef_hastype; eassumption. apply (IHV _ H4).
Qed.

Lemma valinject_hastype:  forall j v v' 
       (V: (val_inject j) v v') T, 
       Val.has_type v' T -> Val.has_type v T.
Proof. intros. inv V; simpl; trivial. Qed.

Lemma forall_valinject_hastype:  forall j vals vals'
            (V:  Forall2 (val_inject j) vals vals') 
            Ts (HTs: Forall2 Val.has_type vals' Ts), 
            Forall2 Val.has_type vals Ts.
Proof.
  intros j vals vals' V.
  induction V; simpl in *; intros.
       trivial.
  inv HTs. constructor. eapply  valinject_hastype; eassumption. apply (IHV _ H4).
Qed.

Definition val_inject_opt (j: meminj) (v1 v2: option val) :=
  match v1, v2 with Some v1', Some v2' => val_inject j v1' v2'
  | None, None => True
  | _, _ => False
  end.

Lemma val_inject_split: forall v1 v3 j12 j23 (V: val_inject (compose_meminj j12 j23) v1 v3),
             exists v2, val_inject j12 v1 v2 /\ val_inject j23 v2 v3. 
Proof. intros. 
   inv V. 
     exists (Vint i). split; constructor.
     exists (Vlong i); split; constructor.
     exists (Vfloat f). split; constructor. 
     apply compose_meminjD_Some in H. rename b2 into b3.
       destruct H as [b2 [ofs2 [ofs3 [J12 [J23 DD]]]]]; subst. 
       eexists. split. econstructor. apply J12. reflexivity. 
          econstructor. apply J23. rewrite Int.add_assoc.
          assert (H: Int.repr (ofs2 + ofs3) = Int.add (Int.repr ofs2) (Int.repr ofs3)). 
            clear - ofs2 ofs3. rewrite Int.add_unsigned.
            apply Int.eqm_samerepr. apply Int.eqm_add; apply Int.eqm_unsigned_repr.
          rewrite H. trivial. 
     exists Vundef. split; constructor.
Qed.     

Lemma forall_lessdef_trans: forall vals1 vals2 (V12: Forall2 Val.lessdef vals1 vals2) 
                                                               vals3  (V23: Forall2 Val.lessdef vals2 vals3) ,  Forall2 Val.lessdef vals1 vals3.
Proof. intros vals1 vals2 V12. 
   induction V12; intros; inv V23; econstructor.
   eapply Val.lessdef_trans; eauto.
          eapply IHV12; trivial.
Qed.

Lemma extends_loc_out_of_bounds: forall m1 m2 (Ext: Mem.extends m1 m2) b ofs,
                loc_out_of_bounds m2 b ofs -> loc_out_of_bounds m1 b ofs.
Proof. intros.
  inv Ext. inv mext_inj.
  intros N.  eapply H. apply (mi_perm _ b 0) in N. rewrite Zplus_0_r in N. assumption. reflexivity.
Qed.

Lemma extends_loc_out_of_reach: forall m1 m2 (Ext: Mem.extends m1 m2) b ofs j
               (Hj: loc_out_of_reach j m2 b ofs), loc_out_of_reach j m1 b ofs.
Proof. intros. unfold loc_out_of_reach in *. intros.
           intros N. eapply (Hj _ _ H). clear Hj H. inv Ext. inv mext_inj.
           specialize (mi_perm b0 _ 0 (ofs - delta) Max Nonempty (eq_refl _)). rewrite Zplus_0_r in mi_perm. apply (mi_perm N).
Qed.

Lemma valinject_lessdef: forall v1 v2 v3 j (V12:val_inject j v1 v2) (V23 : Val.lessdef v2 v3),val_inject j v1 v3.
Proof. intros. 
   inv V12; inv V23; try constructor.
    econstructor. eassumption. trivial.
Qed.

Lemma forall_valinject_lessdef: forall vals1 vals2 j (VInj12 : Forall2 (val_inject j) vals1 vals2) vals3 
                  (LD23 : Forall2 Val.lessdef vals2 vals3), Forall2 (val_inject j) vals1 vals3.
Proof. intros vals1 vals2 j VInj12.
   induction VInj12; intros; inv LD23. constructor.
     econstructor. eapply valinject_lessdef; eassumption.
          eapply (IHVInj12 _ H4).
Qed.

Lemma val_lessdef_inject_compose: forall v1 v2 (LD12 : Val.lessdef v1 v2) j v3
              (InjV23 : val_inject j v2 v3), val_inject j v1 v3.
Proof. intros. 
  apply val_inject_id in LD12.
  apply (val_inject_compose _ _ _ _ _ LD12) in InjV23.
  rewrite <- compose_meminj_idL in InjV23. assumption.
Qed. 

Lemma forall_val_lessdef_inject_compose: forall v1 v2 (LD12 : Forall2 Val.lessdef v1 v2) j v3
              (InjV23 : Forall2 (val_inject j) v2 v3), Forall2 (val_inject j) v1 v3.
Proof. intros v1 v2 H.
  induction H; intros; inv InjV23; econstructor.
       eapply val_lessdef_inject_compose; eassumption.
       apply (IHForall2 _ _ H5). 
Qed. 

Lemma forall_val_inject_compose: forall vals1 vals2 j1 (ValsInj12 : Forall2 (val_inject j1) vals1 vals2)
                vals3 j2 (ValsInj23 : Forall2 (val_inject j2) vals2 vals3),
              Forall2 (val_inject (compose_meminj j1 j2)) vals1 vals3.
Proof.
  intros vals1 vals2 j1 ValsInj12.
  induction ValsInj12; intros; inv ValsInj23; econstructor.
     eapply val_inject_compose; eassumption.
  apply (IHValsInj12 _ _ H4).
Qed.

Lemma val_inject_flat: forall m1 m2 j (Inj: Mem.inject j m1 m2) v1 v2 (V: val_inject j v1 v2),
                val_inject  (Mem.flat_inj (Mem.nextblock m1)) v1 v1.
Proof. intros.
  inv V; try constructor.
    apply val_inject_ptr with (delta:=0).
            unfold Mem.flat_inj. inv Inj.
            destruct (plt b1 (Mem.nextblock m1)).
               trivial.
            assert (j b1 = None). 
              apply mi_freeblocks. assumption. rewrite H in H0. inv H0.
            rewrite Int.add_zero. trivial.
Qed.

Lemma forall_val_inject_flat: forall m1 m2 j (Inj: Mem.inject j m1 m2) vals1 vals2
                (V: Forall2 (val_inject j) vals1 vals2),
                Forall2 (val_inject  (Mem.flat_inj (Mem.nextblock m1))) vals1 vals1.
Proof. intros.
  induction V; intros; try econstructor.
       eapply val_inject_flat; eassumption.
  apply IHV.
Qed.

Lemma po_trans: forall a b c, Mem.perm_order'' a b ->  Mem.perm_order'' b c ->
      Mem.perm_order'' a c.
Proof. intros.
   destruct a; destruct b; destruct c; simpl in *; try contradiction; try trivial.
   eapply perm_order_trans; eassumption.
Qed.

Lemma extends_perm: forall m1 m2 (Ext: Mem.extends m1 m2) b ofs k p,
   Mem.perm m1 b ofs k p -> Mem.perm m2 b ofs k p.  
Proof. intros. destruct Ext. destruct mext_inj.
  specialize (mi_perm b b 0 ofs k p (eq_refl _) H).
  rewrite Zplus_0_r in mi_perm. assumption.
Qed.

Lemma extends_permorder: forall m1 m2 (Ext: Mem.extends m1 m2) (b:block) ofs k,
  Mem.perm_order'' (PMap.get b (Mem.mem_access m2) ofs k)
                   (PMap.get b (Mem.mem_access m1) ofs k).
Proof.
  intros. destruct Ext.  destruct mext_inj as [prm _ _].
  specialize (prm b b 0 ofs k). unfold Mem.perm in prm. 
  remember ((PMap.get b (Mem.mem_access m2) ofs k)) as z.
  destruct z; apply eq_sym in Heqz; simpl  in *. 
    remember ((PMap.get b (Mem.mem_access m1) ofs k)) as zz.
    destruct zz; trivial; apply eq_sym in Heqzz; simpl  in *.
       rewrite Zplus_0_r in prm. rewrite Heqz in prm. 
       specialize (prm p0 (eq_refl _)). apply prm. apply perm_refl. 
  remember ((PMap.get b (Mem.mem_access m1) ofs k)) as zz.
    destruct zz; trivial; apply eq_sym in Heqzz; simpl  in *.
       rewrite Zplus_0_r in prm. rewrite Heqz in prm. 
       specialize (prm p (eq_refl _)). exfalso. apply prm. apply perm_refl. 
Qed.

Lemma fwd_maxperm: forall m1 m2 (FWD: mem_forward m1 m2) b 
  (V:Mem.valid_block m1 b) ofs p,
  Mem.perm m2 b ofs Max p -> Mem.perm m1 b ofs Max p.
Proof. intros. apply FWD; assumption. Qed. 

Lemma fwd_maxpermorder: forall m1 m2 (FWD: mem_forward m1 m2) (b:block) 
  (V:Mem.valid_block m1 b) ofs,
  Mem.perm_order'' (PMap.get b (Mem.mem_access m1) ofs Max)
                   (PMap.get b (Mem.mem_access m2) ofs Max).
Proof.
  intros. destruct (FWD b); try assumption. 
  remember ((PMap.get b (Mem.mem_access m2) ofs Max)) as z.
  destruct z; apply eq_sym in Heqz; simpl  in *.
  remember ((PMap.get b (Mem.mem_access m1) ofs Max)) as zz.
  destruct zz; apply eq_sym in Heqzz; simpl  in *.
  specialize (H0 ofs p).  unfold Mem.perm in H0. unfold Mem.perm_order' in H0. 
  rewrite Heqz in H0. rewrite Heqzz in H0. apply H0. apply perm_refl.
  specialize (H0 ofs p).  unfold Mem.perm in H0. unfold Mem.perm_order' in H0. 
  rewrite Heqz in H0. rewrite Heqzz in H0. apply H0. apply perm_refl.


  remember ((PMap.get b (Mem.mem_access m1) ofs Max)) as zz.
  destruct zz; apply eq_sym in Heqzz; simpl in *; trivial.
Qed.

Lemma po_oo: forall p q, Mem.perm_order' p q = Mem.perm_order'' p (Some q).
Proof. intros. destruct p; trivial. Qed. 

Lemma inject_permorder: forall j m1 m2 (Inj : Mem.inject j m1 m2) (b b':block) ofs'
      (J: j b = Some (b', ofs')) ofs k,
     Mem.perm_order'' (PMap.get b' (Mem.mem_access m2) (ofs + ofs') k)
     (PMap.get b (Mem.mem_access m1) ofs k).
Proof.
  intros. destruct Inj. destruct mi_inj as [prm _ _ ].
  specialize (prm b b' ofs' ofs k). unfold Mem.perm in prm. 
  remember ((PMap.get b' (Mem.mem_access m2) (ofs + ofs') k)) as z.
  destruct z; apply eq_sym in Heqz; simpl  in *. 
    remember ((PMap.get b (Mem.mem_access m1) ofs k)) as zz.
    destruct zz; trivial; apply eq_sym in Heqzz; simpl  in *.
       eapply prm. apply J. apply perm_refl. 
  remember ((PMap.get b (Mem.mem_access m1) ofs k)) as zz.
    destruct zz; trivial; apply eq_sym in Heqzz; simpl  in *.
       eapply prm. apply J. apply perm_refl. 
Qed.

Lemma PermExtNotnonempty: forall m1 m2 (Inj: Mem.extends m1 m2) b ofs p
     (H: ~ Mem.perm m2 b ofs p Nonempty),  ~ Mem.perm m1 b ofs p Nonempty.
Proof. intros. destruct Inj. destruct mext_inj.
intros N. apply H. apply (mi_perm _ _ _ _ _ _ (eq_refl _)) in N. rewrite Zplus_0_r in N. apply N.
Qed.

Lemma  PermInjNotnonempty: forall j m1 m2 (Inj: Mem.inject j m1 m2) b b2 delta (J:j b = Some(b2,delta)) ofs p
     (H:  ~ Mem.perm m2 b2 (ofs+delta) p Nonempty), ~ Mem.perm m1 b ofs p Nonempty.
Proof. intros. destruct Inj. destruct mi_inj.
intros N. apply H. apply (mi_perm _ _ _ _ _ _ J) in N. apply N.
Qed.

(*now in Memory.v
Lemma mem_unchanged_on_refl: forall m f, Mem.unchanged_on f m m.
Proof. intros. split; trivial. 
   intros; split; trivial.
Qed.*)

Lemma inject_LOOR_LOOB: forall m1 m2 j (Minj12 : Mem.inject j m1 m2) m3 m3', 
  Mem.unchanged_on (loc_out_of_reach j m1) m3 m3' -> 
  Mem.unchanged_on (loc_out_of_bounds m2) m3 m3'.
Proof. intros.
     split; intros; eapply H; trivial.
         intros b2; intros. unfold loc_out_of_bounds in H0. intros N. apply H0.
                          inv Minj12. inv mi_inj. apply (mi_perm _ _ _ _ _ _ H2) in N.
                         rewrite <- Zplus_comm in N. rewrite Zplus_minus in N.  apply N.
    intros b2; intros. unfold loc_out_of_bounds in H0. intros N. apply H0.
                          inv Minj12. inv mi_inj. apply (mi_perm _ _ _ _ _ _ H2) in N.
                         rewrite <- Zplus_comm in N. rewrite Zplus_minus in N.  apply N.
Qed.

(*A value that is (if its a pointer) not dangling wrt m - a condition
 like this will probably be need to imposed on after-external return
 values (and thus also on the values returned by halted)*)
Definition val_valid (v:val) (m:mem):Prop := 
     match v with Vptr b ofs => Mem.valid_block m b | _ => True 
     end.

(*In fact val_valid is a slight relaxtion of valid_pointer*)
Lemma valid_ptr_val_valid: forall b ofs m, 
    Mem.valid_pointer m b ofs = true -> val_valid (Vptr b (Int.repr ofs)) m.
Proof. intros.
  apply Mem.valid_pointer_nonempty_perm in H. eapply Mem.perm_valid_block. apply H.
Qed.

Lemma extends_valvalid: forall m1 m2 (Ext: Mem.extends m1 m2) v,
        val_valid v m1 <-> val_valid v m2.
Proof. intros.
  split; intros. destruct v; simpl in *; try econstructor.
     eapply (Mem.valid_block_extends _ _ _ Ext). apply H. 
  destruct v; simpl in *; try econstructor.
     eapply (Mem.valid_block_extends _ _ _ Ext). apply H.
Qed.

Lemma inject_valvalid: forall j m1 m2 (Inj: Mem.inject j m1 m2) v2 (V:val_valid v2 m2) v1,
             val_inject j v1 v2 -> val_valid v1 m1.
Proof. intros.
  inv H. constructor. constructor. constructor.
     simpl in *. eapply Mem.valid_block_inject_1; eassumption. 
     constructor. 
Qed.

(*Preservation of val_valid along an injection only holds 
  if the LHS value is defined*) 
Lemma inject_valvalid_1:
  forall (j : meminj) (m1 m2 : mem),
  Mem.inject j m1 m2 ->
  forall v1 : val,
  val_valid v1 m1 -> forall v2 : val, val_inject j v1 v2 -> 
  match v1 with Vundef => True
      | _ => val_valid v2 m2
  end.
Proof. intros.
  destruct v1; trivial.
  inv H1; trivial.
  inv H1; trivial.
  inv H1; trivial.
  inv H1. simpl in *.
  eapply Mem.valid_block_inject_2; eassumption.
Qed.

(*memories that do not contain "dangling pointers"*)
Definition mem_wd m := Mem.inject_neutral (Mem.nextblock m) m.

Lemma mem_wdI: forall m,
    (forall (b:block) ofs  (R:Mem.perm m b ofs Cur Readable),
                memval_inject  (Mem.flat_inj (Mem.nextblock m)) 
                                             (ZMap.get ofs (PMap.get b (Mem.mem_contents m)))
                                            (ZMap.get ofs (PMap.get b (Mem.mem_contents m)))) -> mem_wd m.
Proof. intros.
  split; intros.
     apply flatinj_E in  H0. destruct H0 as [? [? ?]]; subst. rewrite Zplus_0_r. trivial. 
     apply flatinj_E in  H0. destruct H0 as [? [? ?]]; subst. rewrite Zplus_0_r. trivial. 
     apply flatinj_E in  H0. destruct H0 as [? [? ?]]; subst. rewrite Zplus_0_r.
        apply H. apply H1.
Qed.
        
        
Lemma mem_wd_E: forall m, mem_wd m ->  Mem.inject (Mem.flat_inj (Mem.nextblock m)) m m.
Proof. intros. apply Mem.neutral_inject. apply H. Qed.

Lemma meminj_split_flatinjR: forall j m m' (J:Mem.inject j m' m), mem_wd m -> 
     j = compose_meminj j (Mem.flat_inj (Mem.nextblock m)).
Proof. intros. apply mem_wd_E in H.
   unfold  compose_meminj.
   apply extensionality. intro b. 
   remember (j b). 
   destruct o; trivial. destruct p. unfold Mem.flat_inj in *.
   destruct (plt b0 (Mem.nextblock m)).
     rewrite Zplus_0_r. trivial.
   inv J. apply eq_sym in Heqo. specialize (mi_mappedblocks _ _ _ Heqo).
               exfalso. unfold Mem.valid_block in mi_mappedblocks. xomega.
Qed.

Lemma meminj_split_flatinjL: forall j m m' (J:Mem.inject j m m'), mem_wd m -> 
     j = compose_meminj (Mem.flat_inj (Mem.nextblock m)) j.
Proof. intros. apply mem_wd_E in H.
   unfold  compose_meminj.
   apply extensionality. intro b. 
   unfold Mem.flat_inj in *.
   destruct (plt b (Mem.nextblock m)).
     remember (j b). destruct o. destruct p0.  rewrite Zplus_0_l. trivial. trivial.
  inv J. apply mi_freeblocks. assumption.
Qed.

Lemma mem_wd_inject_splitL: forall j m1 m2
              (J:Mem.inject j m1 m2)  (WD: mem_wd m1),
     Mem.inject (Mem.flat_inj (Mem.nextblock m1)) m1 m1 
     /\ j = compose_meminj (Mem.flat_inj (Mem.nextblock m1)) j.
Proof. intros.
    split. apply mem_wd_E. apply WD.  
    eapply (meminj_split_flatinjL _ _ _ J WD).
Qed.

Lemma mem_wd_inject_splitR: forall j m1 m2
              (J:Mem.inject j m1 m2)  (WD: mem_wd m2),
     Mem.inject (Mem.flat_inj (Mem.nextblock m2)) m2 m2 
     /\ j = compose_meminj j (Mem.flat_inj (Mem.nextblock m2)).
Proof. intros.
    split. apply mem_wd_E. apply WD.  
    eapply (meminj_split_flatinjR _ _ _ J WD).
Qed.

(*Preservation of mem_wd by memory operations*)
Lemma mem_wd_empty: mem_wd Mem.empty.
Proof.  apply Mem.empty_inject_neutral. Qed.

Lemma  mem_wd_alloc: forall m b lo hi m' (ALL: Mem.alloc m lo hi = (m',b))
     (WDm: mem_wd m), mem_wd m'.
Proof. intros. unfold mem_wd in *.
  rewrite (Mem.nextblock_alloc _ _ _ _ _ ALL).
  eapply (Mem.alloc_inject_neutral _ _ _ _ _ _ ALL); try omega.
  inv WDm. 
         split; intros. 
             apply flatinj_E in H. destruct H as [? [? ?]]; subst. rewrite Zplus_0_r. assumption.
             apply flatinj_E in H. destruct H as [? [? ?]]; subst. rewrite Zplus_0_r. assumption.
             apply flatinj_E in H. destruct H as [? [? ?]]; subst. rewrite Zplus_0_r.
                 assert (X: Mem.flat_inj (Mem.nextblock m) b1 = Some (b1, 0)).
                     apply flatinj_I. apply (Mem.perm_valid_block _ _ _ _ _ H0).
                  specialize (mi_memval _ _ _ _ X H0). rewrite Zplus_0_r in mi_memval.
                  eapply memval_inject_incr; try eassumption.
                       intros bb; intros.
                        eapply flatinj_mono; try eassumption; xomega.
       xomega.
Qed. 

Lemma  mem_wd_drop: forall m b lo hi p m' (DROP: Mem.drop_perm m b lo hi p = Some m')
     (WDm: mem_wd m), Mem.valid_block m b -> mem_wd m'.
Proof. intros. unfold mem_wd in *.
  rewrite (Mem.nextblock_drop _ _ _ _ _ _ DROP).
  eapply (Mem.drop_inject_neutral _ _ _ _ _ _ _ DROP); trivial.
Qed.
  
Lemma free_neutral: forall (thr : block) (m : mem) (lo hi : Z) (b : block) (m' : Mem.mem')
  (FREE: Mem.free m b lo hi = Some m'),
  Mem.inject_neutral thr m -> Mem.inject_neutral thr m'.
Proof. intros. inv H. 
  split; intros.
     apply flatinj_E in H. destruct H as [? [? ?]]; subst. rewrite Zplus_0_r. assumption.
     apply flatinj_E in H. destruct H as [? [? ?]]; subst. rewrite Zplus_0_r. assumption.
     apply flatinj_E in H. destruct H as [? [? ?]]; subst. rewrite Zplus_0_r.
        assert (X: Mem.flat_inj thr b1 = Some (b1,0)). apply flatinj_I. assumption.
        assert (Y:= Mem.perm_free_3 _ _ _ _ _ FREE _ _ _ _ H0).
         specialize (mi_memval _ _ _ _ X Y). rewrite Zplus_0_r in *.    
         rewrite (Mem.free_result _ _ _ _ _ FREE) in *. simpl in *. apply mi_memval.
Qed.

Lemma mem_wd_free: forall m b lo hi m' (WDm: mem_wd m)
  (FREE: Mem.free m b lo hi = Some m'), mem_wd m'.
Proof. intros. unfold mem_wd in *.
  eapply free_neutral. apply FREE.
   rewrite (Mem.nextblock_free _ _ _ _ _ FREE). assumption.
Qed.

Lemma mem_wd_store: forall m b ofs v m' chunk (WDm: mem_wd m)
  (ST: Mem.store chunk m b ofs v = Some m')
  (V: val_valid v m), mem_wd m'.
Proof. intros. unfold mem_wd in *.
  eapply Mem.store_inject_neutral. apply ST.
      rewrite (Mem.nextblock_store _ _ _ _ _ _ ST). assumption.
      assert (X:= Mem.store_valid_access_3 _ _ _ _ _ _ ST).
          rewrite (Mem.nextblock_store _ _ _ _ _ _ ST). 
           apply (Mem.valid_access_implies _ _ _ _ _  Nonempty) in X.
                apply Mem.valid_access_valid_block in X. apply X.
            constructor.
      rewrite (Mem.nextblock_store _ _ _ _ _ _ ST). 
          destruct v; try solve [constructor].
            econstructor. eapply flatinj_I. apply V. 
                          rewrite Int.add_zero. trivial.
Qed.

Lemma extends_memwd: 
forall m1 m2 (Ext: Mem.extends m1 m2), mem_wd m2 -> mem_wd m1.
Proof.
  intros. eapply mem_wdI. intros.
  assert (Mem.perm m2 b ofs Cur Readable).
    eapply (Mem.perm_extends _ _ _ _ _ _ Ext R).
  assert (Mem.valid_block m2 b).
     apply (Mem.perm_valid_block _ _ _ _ _ H0). 
  destruct Ext. rewrite mext_next.
  assert (Mem.flat_inj (Mem.nextblock m2) b = Some (b,0)).
    apply flatinj_I. apply H1.
  destruct mext_inj. specialize (mi_memval b ofs b 0 (eq_refl _) R). 
  rewrite Zplus_0_r in mi_memval.
  destruct H. specialize (mi_memval0 b ofs b 0 H2 H0). 
  rewrite Zplus_0_r in mi_memval0. 
  remember (ZMap.get ofs (PMap.get b (Mem.mem_contents m1))) as v.
  destruct v. constructor. constructor.
  econstructor.
    eapply flatinj_I. inv mi_memval. inv H4. rewrite Int.add_zero in H6. 
      rewrite <- H6 in mi_memval0. simpl in mi_memval0. inversion mi_memval0.
      apply flatinj_E in H4. apply H4. 
   rewrite Int.add_zero. reflexivity.
Qed. 

Definition valid_genv {F V:Type} (ge:Genv.t F V) (m:mem) :=
  forall i b, Genv.find_symbol ge i = Some b -> val_valid (Vptr b Int.zero) m.

Lemma valid_genv_alloc: forall {F V:Type} (ge:Genv.t F V) (m m1:mem) lo hi b
    (ALLOC: Mem.alloc m lo hi = (m1,b)) (G: valid_genv ge m), valid_genv ge m1.
Proof. intros. intros x; intros.
  apply (Mem.valid_block_alloc _ _ _ _ _ ALLOC).
  apply (G _ _ H).
Qed.

Lemma valid_genv_store: forall {F V:Type} (ge:Genv.t F V) m m1 b ofs v chunk
    (STORE: Mem.store chunk m b ofs v = Some m1) 
     (G: valid_genv ge m), valid_genv ge m1.
Proof. intros. intros x; intros.
  apply (Mem.store_valid_block_1 _ _ _ _ _ _ STORE).
  apply (G _ _ H).
Qed.

Lemma valid_genv_store_zeros: forall {F V:Type} (ge:Genv.t F V) m m1 b y z 
    (STORE_ZERO: store_zeros m b y z = Some m1)
    (G: valid_genv ge m), valid_genv ge m1.
Proof. intros. intros x; intros.
  apply Genv.store_zeros_nextblock in STORE_ZERO.
  specialize (G _ _ H); simpl in *. unfold Mem.valid_block in *. 
  rewrite STORE_ZERO. apply G.
Qed.

Lemma mem_wd_store_zeros: forall m b p n m1
    (STORE_ZERO: store_zeros m b p n = Some m1) (WD: mem_wd m), mem_wd m1.
Proof. intros until n. functional induction (store_zeros m b p n); intros.
  inv STORE_ZERO; tauto.
  apply (IHo _ STORE_ZERO); clear IHo.
      eapply (mem_wd_store m). apply WD. apply e0. simpl; trivial.
  inv STORE_ZERO.
Qed.

Lemma valid_genv_drop: forall {F V:Type} (ge:Genv.t F V) (m m1:mem) b lo hi p
    (DROP: Mem.drop_perm m b lo hi p = Some m1) (G: valid_genv ge m), 
    valid_genv ge m1.
Proof. intros. intros x; intros.
  apply (Mem.drop_perm_valid_block_1 _ _ _ _ _ _ DROP).
  apply (G _ _ H).
Qed.

Lemma mem_wd_store_init_data: forall {F V} (ge: Genv.t F V) a (b:block) (z:Z) 
  m1 m2 (SID:Genv.store_init_data ge m1 b z a = Some m2),
  valid_genv ge m1 -> mem_wd m1 -> mem_wd m2.
Proof. intros F V ge a.
  destruct a; simpl; intros;
      try apply (mem_wd_store _ _ _ _ _ _ H0 SID); simpl; trivial.
   inv SID; trivial.
   remember (Genv.find_symbol ge i) as d.
     destruct d; inv SID.
     eapply (mem_wd_store _ _ _ _ _ _ H0 H2).
    apply eq_sym in Heqd. apply (H _ _ Heqd). 
Qed.

Lemma valid_genv_store_init_data: 
  forall {F V}  (ge: Genv.t F V) a (b:block) (z:Z) m1 m2
  (SID: Genv.store_init_data ge m1 b z a = Some m2),
  valid_genv ge m1 -> valid_genv ge m2.
Proof. intros F V ge a.
  destruct a; simpl; intros;
  try solve [
    intros x bb; intros; simpl;
      try apply (Mem.store_valid_block_1 _ _ _ _ _ _ SID _ (H _ _ H0))].
    inv SID; trivial.
    remember ( Genv.find_symbol ge i) as d.
      destruct d; inv SID. 
      apply eq_sym in Heqd.
      intros bb; intros; simpl. 
      apply (Mem.store_valid_block_1 _ _ _ _ _ _ H1 _ (H _ _ H0)).
Qed.

Lemma mem_wd_store_init_datalist: forall {F V} (ge: Genv.t F V) l (b:block) 
  (z:Z) m1 m2 (SID: Genv.store_init_data_list ge m1 b z l = Some m2),
  valid_genv ge m1 -> mem_wd m1 -> mem_wd m2.
Proof. intros F V ge l.
  induction l; simpl; intros. 
    inv SID. trivial.
  remember (Genv.store_init_data ge m1 b z a) as d.
  destruct d; inv SID; apply eq_sym in Heqd.
  apply (IHl _ _ _ _ H2); clear IHl H2.
     eapply valid_genv_store_init_data. apply Heqd. apply H. 
  eapply mem_wd_store_init_data. apply Heqd. apply H. apply H0.
Qed. 

Lemma valid_genv_store_init_datalist: forall {F V} (ge: Genv.t F V) l (b:block)
  (z:Z) m1 m2 (SID: Genv.store_init_data_list ge m1 b z l = Some m2),
   valid_genv ge m1 -> valid_genv ge m2.
Proof. intros F V ge l.
  induction l; simpl; intros. 
    inv SID. trivial.
  remember (Genv.store_init_data ge m1 b z a) as d.
  destruct d; inv SID; apply eq_sym in Heqd.
  apply (IHl _ _ _ _ H1); clear IHl H1.
     eapply valid_genv_store_init_data. apply Heqd. apply H. 
Qed. 

Lemma mem_wd_alloc_global: forall  {F V} (ge: Genv.t F V) a m0 m1
   (GA: Genv.alloc_global ge m0 a = Some m1),
   mem_wd m0 -> valid_genv ge m0 -> mem_wd m1.
Proof. intros F V ge a.
destruct a; simpl. intros.
destruct g.
  remember (Mem.alloc m0 0 1) as mm. destruct mm. 
    apply eq_sym in Heqmm. 
    specialize (mem_wd_alloc _ _ _ _ _ Heqmm). intros. 
     eapply (mem_wd_drop _ _ _ _ _  _ GA).
    apply (H1 H). 
    apply (Mem.valid_new_block _ _ _ _ _ Heqmm).
remember (Mem.alloc m0 0 (Genv.init_data_list_size (AST.gvar_init v)) ) as mm.
  destruct mm. apply eq_sym in Heqmm.
  remember (store_zeros m b 0 (Genv.init_data_list_size (AST.gvar_init v)))
           as d. 
  destruct d; inv GA; apply eq_sym in Heqd.
  remember (Genv.store_init_data_list ge m2 b 0 (AST.gvar_init v)) as dd.
  destruct dd; inv H2; apply eq_sym in Heqdd.
  eapply (mem_wd_drop _ _ _ _ _ _ H3); clear H3.
    eapply (mem_wd_store_init_datalist _ _ _ _ _ _ Heqdd).
    apply (valid_genv_store_zeros _ _ _ _ _ _ Heqd).
    apply (valid_genv_alloc ge _ _ _ _ _ Heqmm H0).
  apply (mem_wd_store_zeros _ _ _ _ _ Heqd).
    apply (mem_wd_alloc _ _ _ _ _ Heqmm H).
  unfold Mem.valid_block.
     apply Genv.store_init_data_list_nextblock in Heqdd.
           rewrite Heqdd. clear Heqdd.
      apply Genv.store_zeros_nextblock in Heqd. rewrite Heqd; clear Heqd.
      apply (Mem.valid_new_block _ _ _ _ _  Heqmm).
Qed.

Lemma valid_genv_alloc_global: forall  {F V} (ge: Genv.t F V) a m0 m1
   (GA: Genv.alloc_global ge m0 a = Some m1),
   valid_genv ge m0 -> valid_genv ge m1.
Proof. intros F V ge a.
destruct a; simpl. intros.
destruct g.
  remember (Mem.alloc m0 0 1) as d. destruct d. 
    apply eq_sym in Heqd.
    apply (valid_genv_drop _ _ _ _ _ _ _ GA).
    apply (valid_genv_alloc _ _ _ _ _ _ Heqd H).
remember (Mem.alloc m0 0 (Genv.init_data_list_size (AST.gvar_init v)) )
         as Alloc.
  destruct Alloc. apply eq_sym in HeqAlloc.
  remember (store_zeros m b 0 
           (Genv.init_data_list_size (AST.gvar_init v))) as SZ. 
  destruct SZ; inv GA; apply eq_sym in HeqSZ.
  remember (Genv.store_init_data_list ge m2 b 0 (AST.gvar_init v)) as Drop.
  destruct Drop; inv H1; apply eq_sym in HeqDrop.
  eapply (valid_genv_drop _ _ _ _ _ _ _ H2); clear H2.
  eapply (valid_genv_store_init_datalist _ _ _ _ _ _ HeqDrop). clear HeqDrop.
  apply (valid_genv_store_zeros _ _ _ _ _ _ HeqSZ).
    apply (valid_genv_alloc _ _ _ _ _ _ HeqAlloc H).
Qed.

Lemma valid_genv_alloc_globals:
   forall F V (ge: Genv.t F V) init_list m0 m
   (GA: Genv.alloc_globals ge m0 init_list = Some m),
   valid_genv ge m0 -> valid_genv ge m.
Proof. intros F V ge l.
induction l; intros; simpl in *.
  inv GA. assumption.
remember (Genv.alloc_global ge m0 a) as d.
  destruct d; inv GA. apply eq_sym in Heqd.
  eapply (IHl  _ _  H1). clear H1.
    apply (valid_genv_alloc_global _ _ _ _ Heqd H).
Qed.

Lemma mem_wd_alloc_globals:
   forall F V (ge: Genv.t F V) init_list m0 m
   (GA: Genv.alloc_globals ge m0 init_list = Some m),
   mem_wd m0 -> valid_genv ge m0 -> mem_wd m.
Proof. intros F V ge l.
induction l; intros; simpl in *.
  inv GA. assumption.
remember (Genv.alloc_global ge m0 a) as d.
  destruct d; inv GA. apply eq_sym in Heqd.
eapply (IHl  _ _  H2).
    apply (mem_wd_alloc_global ge _ _ _ Heqd H H0).
    apply (valid_genv_alloc_global _ _ _ _ Heqd H0).
Qed.


Lemma mem_wd_load: forall m ch b ofs v
  (LD: Mem.load ch m b ofs = Some v)
  (WD : mem_wd m), val_valid v m.
Proof. intros.
  destruct v; simpl; trivial.
  destruct (Mem.load_valid_access _ _ _ _ _ LD) as [Perms Align].
  apply Mem.load_result in LD.
  apply eq_sym in LD. apply decode_val_pointer_inv in LD.
  destruct LD.
  destruct ch; inv H; simpl in *.
  unfold mem_wd in WD. unfold Mem.inject_neutral in WD.
  destruct WD.
  assert (Arith: ofs <= ofs < ofs + 4). omega.
  specialize (Perms _ Arith).
  assert (VB:= Mem.perm_valid_block _ _ _ _ _ Perms).
  assert (Z:= flatinj_I (Mem.nextblock m) b VB).
  specialize (mi_memval _ _ _ _ Z Perms).
  inv H0. rewrite Zplus_0_r in mi_memval. rewrite H1 in mi_memval.
  inversion mi_memval. clear H9. subst.
  apply flatinj_E in H5. apply H5.
Qed.

Lemma mem_wd_storebytes: forall m b ofs bytes m' (WDm: mem_wd m)
  (ST: Mem.storebytes m b ofs bytes = Some m')
  (BytesValid: forall v, In v bytes ->
               memval_inject (Mem.flat_inj (Mem.nextblock m)) v v), 
   mem_wd m'.
Proof. intros. apply mem_wdI. intros.
  assert (F: Mem.flat_inj (Mem.nextblock m) b0 = Some (b0, 0)).
        apply flatinj_I. 
        apply (Mem.storebytes_valid_block_2 _ _ _ _ _ ST).
        eapply Mem.perm_valid_block; eassumption.
  apply mem_wd_E in WDm.
  assert (P:= Mem.perm_storebytes_2 _ _ _ _ _ ST _ _ _ _ R).
  specialize (Mem.mi_memval _ _ _ (Mem.mi_inj _ _ _ WDm) _ _ _ _ F P).
  rewrite Zplus_0_r.
  intros MVI.
  rewrite (Mem.nextblock_storebytes _ _ _ _ _ ST).
  rewrite (Mem.storebytes_mem_contents _ _ _ _ _ ST).
  remember (eq_block b0 b).
  destruct s; subst; clear Heqs.
  (*case b0=b*) 
    rewrite PMap.gss.
    remember (zlt ofs0 ofs) as d.
    destruct d; clear Heqd.
    (*case ofs0 < ofs*) 
      rewrite Mem.setN_outside; try (left; assumption).
      assumption.
    (*case ofs0 >= ofs*)
      remember (zlt ofs0 (ofs + (Z.of_nat (length bytes)))) as d.
      destruct d; clear Heqd.
      (*case <*) 
        eapply Mem.setN_property. 
          apply BytesValid.
          split. omega. apply l. 
      (*case >= *)
         rewrite Mem.setN_outside; try (right; assumption).
      assumption.
  (*case b0 <> b*)
    rewrite PMap.gso; trivial.
Qed.

Lemma getN_aux: forall n p c B1 v B2, Mem.getN n p c = B1 ++ v::B2 ->
    v = ZMap.get (p + Z.of_nat (length B1)) c.
Proof. intros n.
  induction n; simpl; intros. 
    destruct B1; simpl in *. inv H. inv H.
    destruct B1; simpl in *. 
      inv H. rewrite Zplus_0_r. trivial.
      inv H. specialize (IHn _ _ _ _ _ H2). subst.
        rewrite Zpos_P_of_succ_nat. 
        remember (Z.of_nat (length B1)) as m. clear Heqm H2. rewrite <- Z.add_1_l.
         rewrite Zplus_assoc. trivial. 
Qed. 

Lemma getN_range: forall n ofs M bytes1 v bytes2,
  Mem.getN n ofs M = bytes1 ++ v::bytes2 ->
  (length bytes1 < n)%nat.
Proof. intros n.
  induction n; simpl; intros.
    destruct bytes1; inv H. 
    destruct bytes1; simpl in *; inv H.
      omega.
    specialize (IHn _ _ _ _ _ H2). omega.
Qed.

Lemma loadbytes_D: forall m b ofs n bytes
      (LD: Mem.loadbytes m b ofs n = Some bytes),
      Mem.range_perm m b ofs (ofs + n) Cur Readable /\
      bytes = Mem.getN (nat_of_Z n) ofs (PMap.get b (Mem.mem_contents m)).
Proof. intros.
  Transparent Mem.loadbytes.
  unfold Mem.loadbytes in LD.
  Opaque Mem.loadbytes.
  remember (Mem.range_perm_dec m b ofs (ofs + n) Cur Readable) as d.
  destruct d; inv LD. auto.
Qed.

Lemma loadbytes_valid: forall m (WD: mem_wd m) b ofs' n bytes
      (LD: Mem.loadbytes m b (Int.unsigned ofs') n = Some bytes)
      v (B: In v bytes),
      memval_inject (Mem.flat_inj (Mem.nextblock m)) v v.
Proof. intros.
  destruct (loadbytes_D _ _ _ _ _ LD) as [Range BB]; subst. 
  assert (L:= Mem.loadbytes_length _ _ _ _ _ LD).
  apply In_split in B. destruct B as [bytes1 [bytes2 B]]. subst.
  assert (I: Int.unsigned ofs' <= (Int.unsigned ofs') + Z.of_nat (length bytes1) < 
                  Int.unsigned ofs' + n).
    assert (II:= getN_range _ _ _ _ _ _ B).
    clear Range LD B L.
    split. omega.
    assert (Z.of_nat (length bytes1) < Z.of_nat (nat_of_Z n)).
        omega.
    rewrite nat_of_Z_eq in H. omega. clear H.
     unfold nat_of_Z in II.
        destruct n. omega. specialize (Pos2Z.is_pos p); omega.
        rewrite Z2Nat.inj_neg in II. destruct bytes1; simpl in II; inv II.
  specialize (Range _ I). 
  assert (F: Mem.flat_inj (Mem.nextblock m) b = Some (b, 0)).
    apply flatinj_I. apply Mem.perm_valid_block in Range. apply Range.
    specialize (Mem.mi_memval _ _ _ WD _ _ _ _ F Range).
    intros. rewrite Zplus_0_r in H.
   apply getN_aux in B. subst. apply H.
Qed.

Lemma freelist_mem_wd: forall l m m'
      (M: Mem.free_list m l = Some m')
      (WD: mem_wd m), mem_wd m'.
Proof. intros l.
  induction l; simpl; intros.
    inv M; trivial.
  destruct a. destruct p.
  remember (Mem.free m b z0 z) as d.
  destruct d; inv M; apply eq_sym in Heqd.
  apply (IHl _ _ H0).
  eapply mem_wd_free; eassumption. 
Qed.

(******** Compatibility of memory operation with mem_forward********)

Lemma store_forward: forall m b ofs v ch m'
      (M:Mem.store ch m b ofs v = Some m'),
      mem_forward m m'.
Proof. intros.
   split; intros.
    eapply Mem.store_valid_block_1; eassumption.
    eapply Mem.perm_store_2; eassumption.
Qed.

Lemma storebytes_forward: forall m b ofs bytes m'
      (M: Mem.storebytes m b ofs bytes = Some m'),
      mem_forward m m'.
Proof. intros.
   split; intros.
    eapply Mem.storebytes_valid_block_1; eassumption.
    eapply Mem.perm_storebytes_2; eassumption.
Qed.

Lemma alloc_forward: 
      forall m lo hi m' b
      (A: Mem.alloc m lo hi = (m',b)),
      mem_forward m m'.
Proof.
intros.
  split; intros.
  eapply Mem.valid_block_alloc; eassumption.
  eapply Mem.perm_alloc_4; try eassumption.
  intros N; subst. eapply (Mem.fresh_block_alloc _ _ _ _ _ A H).
Qed.

Lemma free_forward: forall b z0 z m m'
      (M: Mem.free m b z0 z = Some m'),
      mem_forward m m'.
Proof. intros.
  split; intros.
  eapply Mem.valid_block_free_1; eassumption. 
  eapply Mem.perm_free_3; eassumption. 
Qed.

Lemma freelist_forward: forall l m m'
      (M: Mem.free_list m l = Some m'),
      mem_forward m m'.
Proof. intros l.
  induction l; simpl; intros.
    inv M. apply mem_forward_refl.
  destruct a. destruct p.
  remember (Mem.free m b z0 z) as d.
  destruct d; inv M; apply eq_sym in Heqd.
  specialize (IHl _ _ H0).
  apply free_forward in Heqd.
  eapply mem_forward_trans; eassumption. 
Qed.


Lemma mem_wd_extends_inject: forall m m' (WD: mem_wd m), 
   Mem.extends m m' ->
   Mem.inject (Mem.flat_inj (Mem.nextblock m)) m m'.
Proof. intros.
  destruct H.
  split; intros.
  (*mi_inj*)
    split; intros.
    (*mi_perm*)
      apply flatinj_E in H. destruct H as [? [? ?]]; subst.
        apply (Mem.mi_perm _ _ _ mext_inj b1); trivial.
    (*mi_access*)
      apply flatinj_E in H. destruct H as [? [? ?]]; subst.
        apply (Mem.mi_access _ _ _ mext_inj b1); trivial.
    (*mi_memval*)
      destruct WD as [_ _ MVM]. specialize (MVM _ _ _ _ H H0).
      assert (MM':= Mem.mi_memval _ _ _ mext_inj b1 ofs _ _ (eq_refl _) H0).

      assert (F:= flatinj_E _ _ _ _ H). destruct F as [? [? ?]]; subst.
      remember (ZMap.get ofs (PMap.get b1 (Mem.mem_contents m))) as v.
      inv MM'; try econstructor.
      inv H2.
      inv MVM. rewrite <- H4 in H5. inv H5.  
           rewrite <- H4 in H2. inv H2.
           assert (F:= flatinj_E _ _ _ _ H6). destruct F as [? [? ?]]; subst. apply H6.
           rewrite <- H4 in H5. inv H5.
        trivial. 
  (* mi_freeblocks*)
  unfold Mem.flat_inj.
    destruct (plt b (Mem.nextblock m)).
     exfalso. apply (H p). trivial.
  (*mi_mappedblocks*)
  apply flatinj_E in H. destruct H as [? [? ?]]; subst.
    rewrite mext_next in H1. apply H1.
  (*mi_no_overlap*)
  intros b1; intros.
    apply flatinj_E in H0. destruct H0 as [? [? ?]]; subst.
    apply flatinj_E in H1. destruct H1 as [? [? ?]]; subst.
    left; trivial.
  (*mi_representable*)
  apply flatinj_E in H. destruct H as [? [? ?]]; subst.
    split. omega.
    rewrite Zplus_0_r. apply Int.unsigned_range_2.
Qed. 

Lemma forward_nextblock: forall m m',
  mem_forward m m' -> 
  (Mem.nextblock m <= Mem.nextblock m')%positive.
Proof.
intros m m' H1.
unfold mem_forward in H1.
unfold Mem.valid_block in H1.
apply Pos.leb_le.
remember (Pos.leb (Mem.nextblock m) (Mem.nextblock m')).
destruct b; trivial.
assert (H2: (Mem.nextblock m' < Mem.nextblock m)%positive). apply Pos.leb_gt. rewrite Heqb. trivial. 
destruct (H1 (Mem.nextblock m')); auto.
xomega.
Qed.

Lemma inject_separated_incr_fwd: 
  forall j j' m1 m2 j'' m2'
    (InjSep : inject_separated j j' m1 m2)
    (InjSep' : inject_separated j' j'' m1 m2')
    (InjIncr' : inject_incr j' j'')
    (Fwd: mem_forward m2 m2'),
    inject_separated j j'' m1 m2.
Proof.
intros. intros b. intros. remember (j' b) as z. 
destruct z; apply eq_sym in Heqz.
destruct p. specialize (InjIncr' _ _ _ Heqz). 
rewrite InjIncr' in H0. inv H0.
apply (InjSep _ _ _ H Heqz). 
destruct (InjSep' _ _ _ Heqz H0).
split. trivial.
intros N. apply H2. eapply Fwd. apply N.
Qed.

Lemma inject_separated_incr_fwd2: 
  forall j0 j j' m10 m20 m1 m2,
  inject_incr j j' -> 
  inject_separated j j' m1 m2 -> 
  inject_incr j0 j -> 
  mem_forward m10 m1 -> 
  inject_separated j0 j m10 m20 -> 
  mem_forward m20 m2 -> 
  inject_separated j0 j' m10 m20.
Proof.
intros until m2; intros H1 H2 H3 H4 H5 H6.
apply (@inject_separated_incr_fwd j0 j m10 m20 j' m2); auto.
unfold inject_separated.
intros b1 b2 delta H7 H8.
unfold inject_separated in H2, H5.
specialize (H2 b1 b2 delta H7 H8).
destruct H2 as [H21 H22].
unfold mem_forward in H4, H6.
specialize (H4 b1).
specialize (H6 b2).
split; intros CONTRA.
solve[destruct (H4 CONTRA); auto].
apply H22; auto.
Qed.

Lemma pos_succ_plus_assoc: forall n m,
    (Pos.succ n + m = n + Pos.succ m)%positive.
Proof. intros. 
  do 2 rewrite Pplus_one_succ_r;
           rewrite (Pos.add_comm m);     
           rewrite Pos.add_assoc; trivial.
Qed.

Lemma forall_inject_val_list_inject: 
  forall j args args' (H:Forall2 (val_inject j) args args' ), 
    val_list_inject j args args'.
Proof.
intros j args.
induction args; intros;  inv H; constructor; eauto.
Qed. 

Lemma val_list_inject_forall_inject: 
  forall j args args' (H:val_list_inject j args args'), 
    Forall2 (val_inject j) args args' .
Proof.
intros j args.
induction args; intros;  inv H; constructor; eauto.
Qed. 

Lemma forall_lessdef_val_listless: 
  forall args args' (H: Forall2 Val.lessdef args args'), 
    Val.lessdef_list args args' .
Proof.
intros args.
induction args; intros;  inv H; constructor; eauto.
Qed. 

Lemma val_listless_forall_lessdef: 
  forall args args' (H:Val.lessdef_list args args'), 
    Forall2 Val.lessdef args args' .
Proof.
intros args.
induction args; intros;  inv H; constructor; eauto.
Qed. 

Lemma storev_valid_block_1:
forall ch m addr v m', 
Mem.storev ch m addr v = Some m' -> 
(forall b, Mem.valid_block m b -> Mem.valid_block m' b).
Proof. intros. destruct addr; inv H. eapply Mem.store_valid_block_1; eauto. Qed.

Lemma storev_valid_block_2:
forall ch m addr v m', 
Mem.storev ch m addr v = Some m' -> 
(forall b, Mem.valid_block m' b -> Mem.valid_block m b).
Proof. intros. destruct addr; inv H. eapply Mem.store_valid_block_2; eauto. Qed.

Lemma valid_block_dec: forall m b, {Mem.valid_block m b} +  {~Mem.valid_block m b}.
Proof. intros.
unfold Mem.valid_block.
remember (plt b (Mem.nextblock m)).
destruct s. left; assumption.
right. intros N. xomega.
Qed.
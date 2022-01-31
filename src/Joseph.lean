import category_theory.category.Cat
import category_theory.limits.constructions.pullbacks


-- TODO category_theory/limits defines instance category Type u ✓
-- TODO Find has_pullback ✓ category_theory/limit/shapes/pullback
-- TODO Cat of Cats has pullback
-- TODO Show that category of elements of a functor into Set is the pullback
--      in the category of

/-!
# The category of categories is complete

This file contains constructions of all 1-limits
in the category `Cat` of all categories, treated as a 1-category.

-- TODO sketch the proof

## Implementation notes

It is better to refer to morphisms in Cat using ⟶ (\hom)
rather than ⥤ (\functor) for lean to infer instances.
-/


universes u v

open category_theory
open category_theory.limits
open category_theory.prod
-- GOAL show Cat of Cats has pullbacks



namespace Cat

/-- The product of two categories is a category (category_theory.products.basic) -/
def prod (C D : Cat.{v u}) : Cat.{v u} :=
{ α := (C.α × D.α) }

/-- The product of two categories as a cone over the pair diagram -/
def prod_cone_pair (C D : Cat.{v u}) : cone (pair C D) :=
{ X := prod C D,
  π := map_pair (fst _ _) (snd _ _) }

variables {C D E : Cat.{v u}}

/-- Existence part of the universal property of products -/
def prod_map (f : E ⟶ C) (g : E ⟶ D) : (E ⟶ prod C D) :=
{
  obj := λ z, ⟨ f.obj z , g.obj z ⟩,
  map := λ _ _ h, ⟨ f.map h , g.map h ⟩,
}

lemma eq_to_hom_fst {X Y : C × D} (h : X = Y) :
  prod.fst (eq_to_hom h) = eq_to_hom (congr_arg prod.fst h) :=
by cases h; refl

lemma eq_to_hom_snd {X Y : C × D} (h : X = Y) :
  prod.snd (eq_to_hom h) = eq_to_hom (congr_arg prod.snd h) :=
by cases h; refl

-- lemma eq_to_hom_snd' {X Y : C} {Z W : D} (hXY : X = Y) (hZW : Z = W) :
--   (@eq_to_hom (C × D) _ ⟨ X , Z ⟩ ⟨ Y , W ⟩ (prod.ext hXY hZW)).snd = eq_to_hom hZW :=
-- by cases hXY; cases hZW; refl

namespace is_limit_prod_cone_pair

/-- Existence part of the universal property of products -/
def lift (c : cone (pair C D)) :
  c.X ⟶ (prod_cone_pair C D).X :=
prod_map (c.π.app walking_pair.left) (c.π.app walking_pair.right)

lemma fac (c : cone (pair C D)) (j : walking_pair) :
  lift c ≫ (prod_cone_pair C D).π.app j = c.π.app j :=
category_theory.functor.ext (by intro _; cases j; refl) (by intros; cases j;
  {simpa only [eq_to_hom_refl, category.comp_id, category.id_comp]})

/-- Uniqueness part of the universal property of products -/
lemma uniq
  (c : cone (pair C D)) (F : c.X ⟶ prod C D)
  (h : ∀ (j : discrete walking_pair), F ≫ (prod_cone_pair C D).π.app j = c.π.app j) :
  F = lift c :=
category_theory.functor.ext
begin
  intro,
  apply prod.ext,
  { dsimp only [lift, prod_map, limits.binary_fan.π_app_left],
    rw ← (congr_arg functor.obj (h walking_pair.left)),
    refl },
  { dsimp only [lift, prod_map, limits.binary_fan.π_app_right],
    rw ← (congr_arg functor.obj (h walking_pair.right)),
    refl },
end
begin
  intros i j ϕ,
  apply prod.ext,
  { convert functor.congr_hom (h walking_pair.left) ϕ,
    simpa only [prod_comp_fst, eq_to_hom_fst] },
  { convert functor.congr_hom (h walking_pair.right) ϕ,
    simpa only [prod_comp_snd, eq_to_hom_snd] },
end

end is_limit_prod_cone_pair

/-- The product of categories (as a cone over the pair diagram) is a 1-limit -/
def is_limit_prod_cone_pair :
  is_limit (prod_cone_pair C D) :=
{
  lift := is_limit_prod_cone_pair.lift,
  fac' := is_limit_prod_cone_pair.fac,
  uniq' := is_limit_prod_cone_pair.uniq,
}

/-- The product of categories C × D forms 1-product in the category of categories -/
def limit_cone_prod_cone_pair : limit_cone (pair C D) :=
{
  cone := prod_cone_pair C D,
  is_limit := is_limit_prod_cone_pair
}

instance has_limit_pair : has_limit (pair C D) :=
⟨⟨ limit_cone_prod_cone_pair ⟩⟩

instance has_binary_products : has_binary_products Cat.{v u} :=
has_binary_products_of_has_limit_pair _

variables (F G : C ⟶ D)

/-- The equalizer category of two functors (as a subcategory of the source category C) -/
def equalizer.str' : category.{v} { c : C // F.obj c = G.obj c } :=
{
  hom := λ x y,
    { f : x.1 ⟶ y.1 // F.map f = eq_to_hom x.2 ≫ G.map f ≫ eq_to_hom y.2.symm },
  id := λ x, ⟨ 𝟙 x , by dsimp; simp only [category_theory.category.id_comp,
    category_theory.eq_to_hom_refl, eq_self_iff_true,
    category_theory.eq_to_hom_trans, category_theory.functor.map_id] ⟩,
  comp := λ x y z f g, ⟨ f.1 ≫ g.1 ,
  begin
    have hf := f.2, simp only [subtype.val_eq_coe] at hf,
    have hg := g.2, simp only [subtype.val_eq_coe] at hg,
    dsimp,
    simp only [category_theory.category.assoc,
      category_theory.functor.map_comp, hf, hg],
    dsimp,
    simp only [eq_to_hom_trans_assoc, eq_to_hom_refl, category.id_comp],
  end ⟩,
}

/-- The equalizer category of two functors (as an object in Cat) -/
def equalizer : Cat.{v u} :=
{
  α := { c : C // F.obj c = G.obj c },
  str := equalizer.str' _ _
}

/-- The map embedding the equalizer of two functors into the source category -/
def fork_ι : equalizer F G ⟶ C :=
{
  obj := subtype.val,
  map := λ _ _, subtype.val,
}

lemma fork_condition : fork_ι F G ≫ F = fork_ι F G ≫ G :=
category_theory.functor.ext (λ ⟨ _ , h ⟩, h ) $
λ x y f , f.2

/-- The equalizer of two functors as a cone over the parallel pair diagram (called a fork) -/
def fork : fork F G :=
fork.of_ι (fork_ι F G) (fork_condition _ _)

variables {F G}

namespace is_limit_fork

def lift (c : category_theory.limits.fork F G) : c.X ⟶ (fork F G).X :=
{
  obj := λ x, ⟨ c.ι.obj x , congr_arg (λ F', functor.obj F' x) c.condition ⟩,
  map := λ x y f, ⟨ c.ι.map f , by convert functor.congr_hom c.condition f ⟩,
}

lemma eq_to_hom.val {x y : equalizer F G} (h : x = y) :
  (@eq_to_hom (equalizer F G) _ _ _ h).val = eq_to_hom (by rw h) :=
by cases h; refl

lemma fac (c : category_theory.limits.fork F G) :
  is_limit_fork.lift c ≫ (fork F G).ι = c.ι :=
category_theory.functor.ext (λ _, rfl) $ λ x y f,
calc (lift c ≫ (fork F G).ι).map f = (fork F G).ι.map ((lift c).map f) : rfl
      ... = (fork F G).ι.map ⟨ c.ι.map f , _ ⟩ : rfl
      ... = (fork_ι F G).map ⟨ c.ι.map f , _ ⟩ : rfl
      ... = c.ι.map f : rfl
      ... = eq_to_hom _ ≫ c.ι.map f ≫ eq_to_hom _ :
  by dsimp; simp only [category_theory.category.comp_id,
        category_theory.category.id_comp, eq_self_iff_true]

def uniq (c : category_theory.limits.fork F G) (m : c.X ⟶ (fork F G).X)
  (h : ∀ (j : walking_parallel_pair), m ≫ (fork F G).π.app j = c.π.app j) :
  m = is_limit_fork.lift c :=
category_theory.functor.ext
  ( λ x, subtype.ext $ -- just check the C objects
  calc (m.obj x).1 = (fork F G).ι.obj (m.obj x) : rfl
               ... = (m ≫ (fork F G).ι).obj x : rfl
               ... = (m ≫ (fork F G).π.app walking_parallel_pair.zero).obj x : rfl
               ... = (c.π.app walking_parallel_pair.zero).obj x :
                 by rw (h walking_parallel_pair.zero)
               ... = ((lift c).obj x).1 : rfl )
  ( λ x y f, subtype.ext $ -- just check the C morphisms
  calc (m.map f).1 = (fork F G).ι.map (m.map f) : rfl
               ... = (m ≫ (fork F G).ι).map f : rfl
               ... = (m ≫ (fork F G).π.app walking_parallel_pair.zero).map f : rfl
               ... = eq_to_hom _ ≫ (c.π.app walking_parallel_pair.zero).map f ≫ eq_to_hom _ :
                 functor.congr_hom (h walking_parallel_pair.zero) f
               ... = (eq_to_hom _ ≫ (lift c).map f ≫ eq_to_hom _).1 :
                 by congr; simpa only [eq_to_hom.val] )

end is_limit_fork

open is_limit_fork

/-- The equalizer of two functors (as a cone/fork) is a limit -/
def is_limit_fork :
  is_limit (fork F G) :=
fork.is_limit.mk (fork F G) lift fac uniq

def limit_cone_parallel_pair : limit_cone (parallel_pair F G) :=
{
  cone := fork F G,
  is_limit := is_limit_fork
}

instance has_limit_parallel_pair : has_limit (parallel_pair F G) :=
⟨⟨ limit_cone_parallel_pair ⟩⟩

instance has_equalizers : has_equalizers Cat.{v u} :=
has_equalizers_of_has_limit_parallel_pair _

end Cat

-- instance : has_limits Cat.{v u} := sorry


-- instance has_pullbacks : has_pullbacks Cat.{v u} :=
-- by apply_instance

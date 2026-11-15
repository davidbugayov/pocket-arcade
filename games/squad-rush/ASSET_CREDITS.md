# Asset Credits & Attribution — Pocket Arcade: Squad Rush

All external 3D models were discovered, inspected, and fetched via the Polyfork MCP Server (`https://polyfork.dev/mcp`) from the free low-poly catalog under the **Creative Commons Attribution 4.0 International (CC BY 4.0)** license.

---

## 1. Weapons

### Assault Rifle (Weapon 0)
- **Asset Name**: Rifle
- **Source**: Polyfork (`https://polyfork.dev/asset/rifle-df1815`)
- **Kit**: Primal Future Armory Kit (`primal-future-armory-kit-d7c368`)
- **License**: CC BY 4.0
- **Credit**: "Rifle by Polyfork (https://polyfork.dev/asset/rifle-df1815), CC BY 4.0"
- **Triangles**: 946
- **Modifications**: Re-scaled to 0.48x for soldier hand grip, aligned bore axis forward, custom muzzle flash attachment point.

### Combat Shotgun (Weapon 1)
- **Asset Name**: Scattergun
- **Source**: Polyfork (`https://polyfork.dev/asset/scattergun-66b775`)
- **Kit**: Primal Future Armory Kit (`primal-future-armory-kit-d7c368`)
- **License**: CC BY 4.0
- **Credit**: "Scattergun by Polyfork (https://polyfork.dev/asset/scattergun-66b775), CC BY 4.0"
- **Triangles**: 864
- **Modifications**: Re-scaled to 0.52x, forward grip alignment, multi-projectile spread spawn point.

### Plasma Minigun (Weapon 2)
- **Asset Name**: Rotary Cannon
- **Source**: Polyfork (`https://polyfork.dev/asset/rotary-cannon-e2114b`)
- **Kit**: Primal Future Armory Kit (`primal-future-armory-kit-d7c368`)
- **License**: CC BY 4.0
- **Credit**: "Rotary Cannon by Polyfork (https://polyfork.dev/asset/rotary-cannon-e2114b), CC BY 4.0"
- **Triangles**: 922
- **Modifications**: Re-scaled to 0.38x, animated rotary barrel cluster spin (`cluster` node rotation on Z axis during firing).

---

## 2. Boss Units

### Level 1 Boss: Iron Sentinel (Heavy Robot)
- **Asset Name**: Service Robot
- **Source**: Polyfork (`https://polyfork.dev/asset/service-robot-93f82e`)
- **Kit**: Space Base Kit (`space-base-kit-cf65de`)
- **License**: CC BY 4.0
- **Credit**: "Service Robot by Polyfork (https://polyfork.dev/asset/service-robot-93f82e), CC BY 4.0"
- **Triangles**: 2706
- **Modifications**: Scaled to 2.2x (3.9m tall bipedal combat mech), added dual heavy shoulder cannons with warning lasers and muzzle charge telegraph indicators.

### Level 2 Boss: Heavy War Tank
- **Asset Name**: Medium Tank
- **Source**: Polyfork (`https://polyfork.dev/asset/medium-tank-65da6b`)
- **Kit**: World War II Kit (`world-war-ii-ba2289`)
- **License**: CC BY 4.0
- **Credit**: "Medium Tank by Polyfork (https://polyfork.dev/asset/medium-tank-65da6b), CC BY 4.0"
- **Triangles**: 2534
- **Modifications**: Scaled to 1.05x, animated turret rotation tracking player X position, cannon recoil tween, high-visibility attack warning crosshair.

### Level 3 Boss: Dread Titan (Colossal Walker)
- **Asset Name**: Cargo walker
- **Source**: Polyfork (`https://polyfork.dev/asset/cargo-walker-6b8a31`)
- **Kit**: Sky Town (`salvage-commons-d0be9f`)
- **License**: CC BY 4.0
- **Credit**: "Cargo walker by Polyfork (https://polyfork.dev/asset/cargo-walker-6b8a31), CC BY 4.0"
- **Triangles**: 2887
- **Modifications**: Scaled to 0.52x, aligned feet to bridge deck, underslung dual plasma blast batteries with charging energy spheres.

---

## 3. Obstacles

### Tire Stack (Obstacle 0)
- **Asset Name**: Tyre Stack
- **Source**: Polyfork (`https://polyfork.dev/asset/tyre-stack-ad4692`)
- **Kit**: Roadside Americana (`roadside-americana-50d40c`)
- **License**: CC BY 4.0
- **Credit**: "Tyre Stack by Polyfork (https://polyfork.dev/asset/tyre-stack-ad4692), CC BY 4.0"
- **Triangles**: 2368
- **Modifications**: Scaled to 1.4x, matched CylinderShape3D collision and damage response.

### Wooden Ammunition Crate (Obstacle 1)
- **Asset Name**: Ammunition Crate
- **Source**: Polyfork (`https://polyfork.dev/asset/ammunition-crate-a5c550`)
- **Kit**: World War II Kit (`world-war-ii-ba2289`)
- **License**: CC BY 4.0
- **Credit**: "Ammunition Crate by Polyfork (https://polyfork.dev/asset/ammunition-crate-a5c550), CC BY 4.0"
- **Triangles**: 674
- **Modifications**: Scaled to 1.3x, matched BoxShape3D collision and destructible HP billboard.

### Hazard Barrel (Obstacle 2)
- **Asset Name**: Barrel
- **Source**: Polyfork (`https://polyfork.dev/asset/barrel-8d63c4`)
- **Kit**: Pirate Cove Kit (`pirate-cove-2ebea4`)
- **License**: CC BY 4.0
- **Credit**: "Barrel by Polyfork (https://polyfork.dev/asset/barrel-8d63c4), CC BY 4.0"
- **Triangles**: 552
- **Modifications**: Scaled to 1.35x, matched CylinderShape3D collision and explosive destruction fx.

### Concrete Jersey Barrier (Obstacle 3)
- **Asset Name**: Skated Jersey Barrier
- **Source**: Polyfork (`https://polyfork.dev/asset/skated-jersey-barrier-7f0a04`)
- **Kit**: Skatepark Kit (`skatepark-0922a9`)
- **License**: CC BY 4.0
- **Credit**: "Skated Jersey Barrier by Polyfork (https://polyfork.dev/asset/skated-jersey-barrier-7f0a04), CC BY 4.0"
- **Triangles**: 508
- **Modifications**: Scaled to 1.15x, matched BoxShape3D collision barrier shape.

---

## 4. Soldiers (Stylized Low-Poly Soldier System & Polyfork Comparison)

### External Asset Evaluation (Polyfork Free Catalog)
- **Inspected Models**:
  - `Infantry Rifleman` (`https://polyfork.dev/asset/infantry-rifleman-c1c0a5`): 3,651 triangles, 30 skeleton bones, unrigged/unanimated, realistic WWII infantry uniform.
  - `Squad Officer` (`https://polyfork.dev/asset/squad-officer-e5c52b`): 3,279 triangles, 30 skeleton bones, unrigged, realistic WWII officer uniform.
- **Why External Models Were Not Selected for Squad Combatants**:
  1. *Performance & Render Budget*: 60 combatants with 3,651 triangles each would submit 219,060 skinned triangles and evaluate 60 skeletal node graphs per frame on the mobile Mali-G76 MC4 GPU, causing catastrophic frame drops below 10 FPS.
  2. *Artistic Direction & Readability*: The elevated 45° camera perspective requires bold, rounded, high-contrast silhouettes. Realistic WWII trench uniforms with drab muddy colors and realistic human proportions become unreadable dark smudges on mobile screens.
  3. *Animation Needs*: Polyfork character models lack built-in running, banking tilt, weapon recoil kickback, and casualty tumble animations.

### Custom Stylized Rounded Fighter System (`StylizedSoldier.gd`)
- **Author**: Custom high-performance modular soldier model engineered specifically for stable 30-60 FPS performance on mid-range Android devices with 60 combatants.
- **Silhouette & Geometry**:
  - Oversized rounded combat helmet dome with flared brow visor rim and ear protection pads.
  - High-emission glowing panoramic tactical visor band (luminous Cyan for allies, fiery Amber/Ruby for enemies) ensuring instant readability from 30+ meters away in camera view.
  - Compact contoured plate carrier armor vest with rounded collar and shoulder pauldrons.
  - Two-handed ready weapon grip firmly holding weapons at chest level.
  - Rounded capsule limbs with combat boots.
- **Coherent Gear Variations**:
  - *Variant 0: Heavy Trooper* — Reinforced heavy collar, dual shoulder pauldrons, solid tactical belt.
  - *Variant 1: Tactical Specialist* — Helmet communications box with radio antenna mast, dual chest magazine pouches.
  - *Variant 2: Scout / Breacher* — Brow sensor goggles, diagonal combat bandolier strap, rear survival/radio pack.
  - *Color Harmonization* — Subtle uniform fabric tint shifts (classic tactical navy, dark stealth navy, bright cobalt).
- **Procedural Animations**:
  - Energetic bouncy running stride with vertical body bobbing.
  - Dynamic banking tilt into turns when swiping left/right.
  - Snappy weapon recoil kickback with muzzle flash star.
  - Expressive defeat tumbling ragdoll fall and dissolve.
- **Rendering Architecture**:
  - Pre-baked shared procedural `ArrayMesh` surfaces via `SurfaceTool` with 100% shared static materials.
  - Pre-baked single-draw-call weapon meshes.
  - Articulated 4-mesh front rows + single-mesh 1-draw-call rear row LOD, reducing squad draw calls from 3,800 to ~90-120 draw calls.

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

## 4. Soldiers (Stylized Low-Poly Soldier System)
- **Author**: Custom high-performance modular soldier model (`StylizedSoldier.gd`) engineered for 60 FPS mobile performance with 50+ combatants.
- **Components**: Tactical combat helmet, glowing visor (Cyan for blue allies, Red/Amber for enemies), plate carrier vest, articulated shoulder guards, dual-grip weapon holding arms with firing recoil kickback, and stride-animated running legs.
- **Animation**: Procedural walk/run cycle, firing recoil with muzzle flash, spawn scale-pop, and defeat tumbling ragdoll fade.

当前项目里 **`ShadowColor.a` 作为反向强度** 的典型公式是：

```hlsl
lerp(1, _ShadowColor.rgb, 1 - saturate(_ShadowColor.a))
```

也就是：

- `A = 1`：基本不使用 `ShadowColor`
- `A = 0`：完整使用 `ShadowColor.rgb`

目前属于这个语义的主要有：

**Item / Opaque / Alpha 主体**
- `xukmi/MainOpaquePlus`
- `xukmi/MainOpaquePlusTess`
- `xukmi/MainAlphaPlus`
- `xukmi/MainAlphaPlusTess`
- `xukmi/MainOpaqueBlend`
- `xukmi/MainHeightAlpha`
- `xukmi/MainHeightAlphaDisplace`

**MainItem 系列**
- `xukmi/MainItemPlus`
- `xukmi/MainItemPlusTess`
- `xukmi/MainItemAlphaPlus`
- `xukmi/MainItemAlphaPlusTess`

注意：`MainItemAlphaPlus` / Tess 的 **Forward 主 pass** 因为 `ALPHA_SHADER` 分支，`ShadowColor.a` 不像 opaque 那样完整生效；但它的部分 outline/暗部路径里仍有反向强度公式。

**Studio Item 非 Alpha**
- `xukmi/MainItemStudioPlus`
- `xukmi/MainItemStudioPlusTess`

Studio alpha 是特例，不完全是这个语义。

**Skin 系列**
- `xukmi/SkinPlus`
- `xukmi/SkinPlusReflect`
- `xukmi/SkinPlusTess`
- `xukmi/SkinPlusTessReflect`
- `xukmi/SkinAlphaPlus`
- `xukmi/SkinAlphaPlusReflect`
- `xukmi/SkinAlphaPlusTess`
- `xukmi/SkinAlphaPlusTessReflect`

**不是这个反向强度语义的主要例外**

- Hair 全系列：`HairPlus`、`HairPlusReflect`、`HairPlusTess`、`HairFrontPlus...` 等
  Hair 的 `ShadowColor` 主要用 RGB 做暗部重映射，基本不按 `A=0 强 / A=1 弱` 这套逻辑走。

- `MainItemStudioAlphaPlus` / `MainItemStudioAlphaPlusTess`
  Studio alpha 分支会先把 `_ShadowColor.rgb` 归一化后乘 `_ShadowColor.a`，再把 alpha 强制设回 1；所以它不是普通反向强度。

- Eye / EyeW 系列
  基本不走 `ShadowColor` 这套身体/物品暗部逻辑。

所以最容易记的规则是：**普通 Item、Opaque、Skin 大多是 `ShadowColor.a` 反向强度；Hair 和 StudioAlpha 不按这个规则。**

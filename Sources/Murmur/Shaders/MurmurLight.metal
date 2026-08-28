// The Light pack. Six thinking indicators made of light that has been THROUGH
// something before it reaches the eye: water, air, fog, dust, heat. The Liquid
// pack has the pour's weight and the Ink pack has paper's capillary time; this
// family's subject is a medium, and the medium is what moves.
//
//   mg_caustic  the fold of a caustic on a pool floor: a soft web, drawn as the
//               zero set of the ray map's Jacobian, never as cells.
//   mg_aurora   a curtain of light folded in slow air. Hard lower border, soft
//               top, brightness where the folds overlap. Nothing falls.
//   mg_ember    the air above a warm floor: light pooled low, the coals seen
//               through their own rising shimmer.
//   mg_lantern  one lamp of CONSTANT brightness behind drifting fog. What moves
//               is the fog, and the shadows it throws across its own light.
//   mg_mirage   the desert road: one small distant light, its image sliced and
//               doubled by layered air and folded below the inversion into an
//               inverted second copy. The bands themselves are never drawn.
//   mg_oculus   an aperture admitting light, opening as the thought completes.
//               Open is the rest state, and rest is not a freeze.
//   mg_dapple   canopy light: two layers of leaves sliding past each other, and
//               the floor lit wherever their gaps happen to line up.
//   mg_eclipse  a soft dark mass wandering across a light it never leaves and
//               never clears. The corona at its limb is the whole picture.
//
// THE FAMILY LAW, and every one of these obeys it. Time enters where a
// COORDINATE IS READ, never as a brightness multiplier. That is not a style
// preference here, it is the whole difference between a lantern and a novelty
// lamp: mg_lantern's source is exactly as bright at t = 300 as it was at t = 0,
// and the picture is alive anyway because the medium in front of it is not
// where it was. A light that throbs is the failure mode this family is most
// exposed to, so none of the six modulates emission with time at all. Check any
// of them by deleting `time` from the field and looking at what stops: it must
// be the medium, never the light.
//
// THE SCALE CONSTRAINT, which is new to this pack and governs every frequency
// below. These are indicators, drawn at 46 pt in a chat row and at 300 pt on a
// design surface, and the uv frame here is normalised so ONE UV UNIT IS THE
// SHORT SIDE. At 46 pt that means a noise cell of 0.06 uv is under three
// points across. Anything finer sparkles instead of drifting, which is the
// opposite of calm and is also what aliases first. So the rule the numbers here
// are picked against: the FINEST octave's cell stays at or above ~0.06 uv.
// With the kit's 2.03 lacunarity that caps a three octave field near f = 4 and
// a two octave field near f = 8, and where a frequency below sits at the top of
// its range the comment says which octave count is holding it there.
//
// THE TEMPO, and what `speed` = 1.0 means. These were first tuned to the calm of
// an ambient card, and on device the whole set read one notch too still: an
// indicator is ATTENTION, not atmosphere, and a thinking indicator that barely
// moves says the thinking has stopped. Every internal rate constant below was
// therefore lifted between 1.5x and 2x. The `speed` uniform still means "the
// designed tempo"; what changed is what the designed tempo IS.
//
// The lift is not uniform inside a style, and the rule it follows is worth
// keeping. Where a style has a CARRIER motion (a whole pattern translating) and
// a DETAIL motion (the same pattern reorganising in place), the carrier takes
// the full 2x and the detail takes about 1.5x. Translation reads as speed;
// churn reads as busyness. Lift them together and the field gets faster AND
// noisier, which is how calm turns into stormy. Lift the carrier harder and it
// reads faster at the same density, which is what was actually wanted.
//
// Two rates deliberately did not take the full lift. mg_lantern's light does not
// move at all, by contract, so its whole increase went into the fog drifting in
// front of it. mg_oculus's opening arc stays at 2.6 REAL seconds, because it
// describes an event rather than a texture and it has to keep meaning what it
// says; only the medium under it sped up.
//
// THE CONTAINMENT. The view clips to a circle. A clip that lands on lit pixels
// draws a hard rim, and a hard rim on an organic form is the one edge this
// house never ships, so every style brings its light down to pure ink well
// inside length(uv) = 0.5 through mg_hold before the clip is ever consulted.
// The clip should have nothing left to cut.
//
// COPIED HELPERS. Cross-file Metal linkage is not guaranteed, so the kit is
// copied out of FieldLab.metal and FieldPackPour.metal VERBATIM under an mg_
// prefix, the way the house has done it before. Copied, unchanged except for
// the name:
//
//   mg_hash, mg_grad3, mg_noised3, mg_noise3, MG_ROT, mg_fbmd3, mg_fbm3,
//   mg_srgb_to_linear, mg_linear_to_srgb, mg_linear_to_oklab,
//   mg_oklab_to_linear, mg_lch, MGPalette, mg_palette, mg_shade, mg_out,
//   mg_knee, mg_hash1, mg_vnoise1, mg_fbm1
//
// Their comments come with them: the reasoning is the part worth carrying.
// mg_hold is the one helper written rather than copied, and it says why.
// Nothing here is behind the prefix that the six styles do not call.
//
// A NOTE ON THE NUMBERS, in the pour's spirit of saying which is which. The
// pour's constants were fitted against a photograph of the shipped card. These
// were not: they are reasoned from the octave weights, the uv scale above, and
// what each medium actually does, and the reviewing session's screenshots are
// the first time any of them meets an eye. Where a constant is the one to move
// if the picture disagrees, the comment names it.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's, verbatim, renamed.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint mg_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 mg_grad3(int3 c) {
    uint h = mg_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// Gradient noise and its analytic gradient, in one evaluation.
/// Returns (value, d/dx, d/dy, d/dz). Quintic interpolation, so the derivative
/// is itself continuous: lighting built on it has no facets at cell walls.
static float4 mg_noised3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float3 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);
    int3 c = int3(i);

    float3 ga = mg_grad3(c + int3(0, 0, 0));
    float3 gb = mg_grad3(c + int3(1, 0, 0));
    float3 gc = mg_grad3(c + int3(0, 1, 0));
    float3 gd = mg_grad3(c + int3(1, 1, 0));
    float3 ge = mg_grad3(c + int3(0, 0, 1));
    float3 gf = mg_grad3(c + int3(1, 0, 1));
    float3 gg = mg_grad3(c + int3(0, 1, 1));
    float3 gh = mg_grad3(c + int3(1, 1, 1));

    float va = dot(ga, f - float3(0.0, 0.0, 0.0));
    float vb = dot(gb, f - float3(1.0, 0.0, 0.0));
    float vc = dot(gc, f - float3(0.0, 1.0, 0.0));
    float vd = dot(gd, f - float3(1.0, 1.0, 0.0));
    float ve = dot(ge, f - float3(0.0, 0.0, 1.0));
    float vf = dot(gf, f - float3(1.0, 0.0, 1.0));
    float vg = dot(gg, f - float3(0.0, 1.0, 1.0));
    float vh = dot(gh, f - float3(1.0, 1.0, 1.0));

    float k1 = vb - va;
    float k2 = vc - va;
    float k3 = ve - va;
    float k4 = va - vb - vc + vd;
    float k5 = va - vc - ve + vg;
    float k6 = va - vb - ve + vf;
    float k7 = -va + vb + vc - vd + ve - vf - vg + vh;

    float value = va + k1 * u.x + k2 * u.y + k3 * u.z
                + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x
                + k7 * u.x * u.y * u.z;

    // Two contributions: the gradients blended by the same trilinear weights,
    // plus the interpolant's own rate of change through the corner values.
    float3 grad = ga
        + u.x * (gb - ga) + u.y * (gc - ga) + u.z * (ge - ga)
        + u.x * u.y * (ga - gb - gc + gd)
        + u.y * u.z * (ga - gc - ge + gg)
        + u.z * u.x * (ga - gb - ge + gf)
        + u.x * u.y * u.z * (-ga + gb + gc - gd + ge - gf - gg + gh)
        + du * float3(k1 + k4 * u.y + k6 * u.z + k7 * u.y * u.z,
                      k2 + k5 * u.z + k4 * u.x + k7 * u.z * u.x,
                      k3 + k6 * u.x + k5 * u.y + k7 * u.x * u.y);

    return float4(value, grad);
}

/// The value alone, for the places that never ask what the slope is: the warp
/// offsets and the sheets behind the first. Roughly a third cheaper.
static float mg_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(mg_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(mg_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(mg_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(mg_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(mg_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(mg_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(mg_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(mg_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

/// The per-octave rotation. Orthonormal, so its transpose is its inverse, which
/// is exactly what the chain rule below needs. Without it every octave stacks on
/// the same lattice axes and the field grows a visible plaid.
constant float3x3 MG_ROT = float3x3(float3( 0.00,  0.80,  0.60),
                                    float3(-0.80,  0.36, -0.48),
                                    float3(-0.60, -0.48,  0.64));

/// fBm carrying its own derivative. `mt` accumulates the transpose of the map
/// from the base domain to the current octave's domain, so each octave's
/// gradient is rotated back before it is summed. Returns (value, gradient).
static float4 mg_fbmd3(float3 p, int octaves, float lacunarity, float gain) {
    float3x3 rotT = transpose(MG_ROT);
    float3x3 mt = float3x3(1.0);
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    float3 grad = float3(0.0);
    for (int i = 0; i < octaves; i++) {
        float4 n = mg_noised3(q);
        value += amp * n.x;
        grad += amp * (mt * n.yzw);
        amp *= gain;
        q = lacunarity * (MG_ROT * q);
        mt = lacunarity * (mt * rotT);
    }
    return float4(value, grad);
}

static float mg_fbm3(float3 p, int octaves, float lacunarity, float gain) {
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    for (int i = 0; i < octaves; i++) {
        value += amp * mg_noise3(q);
        amp *= gain;
        q = lacunarity * (MG_ROT * q);
    }
    return value;
}

static inline float3 mg_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 mg_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 mg_linear_to_oklab(float3 c) {
    float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
    float l_ = pow(max(l, 0.0), 1.0 / 3.0);
    float m_ = pow(max(m, 0.0), 1.0 / 3.0);
    float s_ = pow(max(s, 0.0), 1.0 / 3.0);
    return float3(0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
                  1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
                  0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_);
}

static inline float3 mg_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 mg_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the day tone the ribbon wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MGPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MGPalette mg_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = mg_linear_to_oklab(mg_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = mg_linear_to_oklab(mg_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MGPalette p;
    p.s0 = ink;
    p.s1 = mg_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = mg_lch(L, C, h);
    p.s3 = mg_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; mg_out does the encoding.
static float3 mg_shade(MGPalette p, float t) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    return mg_oklab_to_linear(lab);
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 mg_out(float3 linearRGB, float2 pixel) {
    float3 c = mg_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float mg_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
}

static inline float mg_hash1(float cell, float lane) {
    return float(mg_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

/// Value noise on a line, quintic-interpolated so its slope is continuous and
/// a silhouette built on it has no corners the eye can find.
static inline float mg_vnoise1(float x, float lane) {
    float i = floor(x), f = x - i;
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(mg_hash1(i, lane), mg_hash1(i + 1.0, lane), u) * 2.0 - 1.0;
}

/// fBm on a line. Amplitude halves, frequency a hair past doubles (2.03, so no
/// two octaves ever land on the same cell wall). Range is about plus or minus
/// one for four octaves.
static float mg_fbm1(float x, int octaves, float lane) {
    float v = 0.0, amp = 0.5, f = 1.0;
    for (int i = 0; i < octaves; i++) {
        v += amp * mg_vnoise1(x * f, lane + float(i) * 37.0);
        amp *= 0.5;
        f *= 2.03;
    }
    return v;
}

// MARK: - The circle
//
// The one helper written rather than copied, and it replaces fl_edge for a
// reason worth stating.

/// The circle's own edge law. FieldLab's fl_edge fades a field toward a
/// rectangular frame in a 0...1 uv, and neither half of that is true here: the
/// frame is a CIRCLE, the uv is centred at zero, and the view puts a hard
/// clipShape on the result. A clip is not a fade. If any light is still lit
/// where the clip lands, the indicator grows a crisp circular rim, and a crisp
/// rim on an organic form is the one edge this house does not ship.
///
/// So r is measured against the clip radius (1.0 is exactly where the clip
/// falls) and everything is gone before 0.94 of it: at 46 pt that leaves about
/// a point and a half of pure ink for the antialiased clip edge to land in, and
/// at 300 pt it leaves nine. `reach` is clamped rather than trusted, because a
/// style that wanted a wider field would otherwise be able to hand the clip
/// something to cut, and no style is allowed to make that mistake.
static inline float mg_hold(float2 uv, float reach) {
    float r = length(uv) * 2.0;
    float a = clamp(reach, 0.30, 0.64);
    return 1.0 - smoothstep(a, a + 0.30, r);
}

// MARK: - 1. Caustic

// CAUSTIC. Light refracted through moving water, landing on a floor.
//
// The web is the whole species, and the honest question is what a caustic web
// actually IS. It is not a cell pattern, which is why every Voronoi version of
// this reads as a lie: it is the FOLD of the map that carries rays from the
// water surface to the floor. Take a surface height h, refract, and every point
// of the surface sends its ray to
//
//     floor(p) = p - k grad h(p)
//
// The floor's brightness at a point is the number of rays that land in a unit
// area there, which is one over the determinant of that map's Jacobian:
//
//     J = I - k H,      H = the Hessian of h
//     det J = (1 - k Hxx)(1 - k Hyy) - k^2 Hxy^2
//
// Where det J crosses zero, an area of surface collapses onto a curve of floor
// and the light there is unbounded. That curve family, smooth and wandering and
// closing on itself, IS the web. It is drawn here as w / (w + |det J|), which is
// the same shape as 1/|det| with a width instead of an infinity, so the threads
// are soft at every scale and there is no exposure at which they blow out.
//
// The Hessian costs two extra taps and no finite differencing of the VALUE,
// because the kit's mg_fbmd3 already returns the analytic gradient: differencing
// the gradient once gives the second derivative for the price of two more field
// evaluations instead of the eight a value-space Hessian would need. That is the
// derivative in the kit finally earning its keep. Six taps total.
//
// TWO OCTAVES, and this one is physics rather than budget. A water surface is
// smooth: capillary detail exists but it does not focus, and adding octaves here
// puts the Hessian's energy in the top octave, which fills the frame with tiny
// closed loops and lands exactly on the cellular reading this species must never
// have. Two octaves keeps the folds broad and the web legible at 20 pt.
//
// THE NUMBER TO MOVE. `k` below is the focusing strength, and it is reasoned
// rather than photographed: the fBm's second-derivative gain over its base
// octave is 0.5 + 0.25 * 2.03^2 = 1.53, the base octave's own curvature runs
// around 4, so H sits near 6 typical and k near 0.16 puts k H at about 1, which
// is where folds start forming. If the web comes out sparse, raise the 0.20; if
// it comes out busy, lower it. Nothing else in this style needs to move.
//
//   c0 web     how much surface there is across the frame: fewer, broader folds
//              to more of them.
//   c1 depth   how far the floor is below the surface. Deeper water focuses
//              harder, so this is literally k.
//   c2 swim    NOT a second speed dial. It sets how much of the motion is the
//              water body TRAVELLING across the floor versus reorganising in
//              place. At 0 the web churns without going anywhere; at 1 it
//              drifts, and the drift is what makes a small indicator read as
//              current rather than as boiling.
//   c3 focus   thread width. Broad soft glow to a tight bright filigree.
[[ stitchable ]] half4 mg_caustic(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));                    // the pour's own guard
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float web = clamp(c0, 0.0, 1.0);
    float deepK = clamp(c1, 0.0, 1.0);
    float swim = clamp(c2, 0.0, 1.0);
    float focus = clamp(c3, 0.0, 1.0);

    // The surface domain. f = 4.8 at the default; two octaves puts the finest
    // cell at 1/(4.8 * 2.03) = 0.10 uv, which is five points at 46 pt: broad
    // enough to drift, coarse enough never to sparkle.
    float f = (3.2 + 3.2 * web) / S;
    // The two motions, and they are different things. The drift is the body of
    // water moving over the floor and it carries the whole pattern with it. The
    // churn is the third noise axis, which reorganises the surface without
    // translating it. `swim` trades between them; neither is ever zero, because
    // still water is not this species.
    float2 drift = float2(0.104, 0.038) * t * (0.30 + 1.55 * swim);
    float churn = t * (0.235 - 0.085 * swim);
    float3 p = float3((uv + drift) * f, churn);

    // The Hessian, by differencing the analytic gradient. e = 0.10 of a cell is
    // small enough to be a second derivative and large enough to low pass the
    // very top of the octave stack, which is the same softening a real lens
    // aperture does to a caustic.
    const float e = 0.10;
    float4 s0 = mg_fbmd3(p, 2, 2.03, 0.5);
    float4 sx = mg_fbmd3(p + float3(e, 0.0, 0.0), 2, 2.03, 0.5);
    float4 sy = mg_fbmd3(p + float3(0.0, e, 0.0), 2, 2.03, 0.5);
    float inv = 1.0 / e;
    float hxx = (sx.y - s0.y) * inv;
    float hxy = (sx.z - s0.z) * inv;
    float hyy = (sy.z - s0.z) * inv;

    float k = 0.06 + 0.20 * deepK;
    float det = (1.0 - k * hxx) * (1.0 - k * hyy) - k * k * hxy * hxy;

    // The fold, with a width instead of a singularity. Bounded in (0, 1] by
    // construction, so a badly tuned k cannot produce a white frame: too little
    // focusing gives a dim even wash, too much gives a busy one, and neither
    // clips.
    float w = 0.42 - 0.30 * focus;
    float fold = w / (w + abs(det));
    fold = pow(fold, 1.0 + 0.9 * focus);

    // The floor is not black between the threads. It is lit by the same light,
    // just unfocused, and the surface's own thickness modulates how much gets
    // through. Costs nothing: s0.x is already in hand.
    float ambient = 0.115 + 0.085 * (0.5 + 0.5 * s0.x);
    float lit = ambient + (0.44 + 0.16 * deepK) * fold;

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.88));
    // The emission colour is taken NEAR THE TONE and not at the rail's pale
    // stop. The pour learned this the expensive way: once the knee has
    // saturated red and green, a pale stop takes blue up with them and warm
    // metal turns white. Sitting the emission at 0.80 lets the knee make its
    // own yellow out of the tone instead.
    float3 em = mg_shade(pal, 0.80) * (0.42 * pow(fold, 3.2)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.60));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 2. Aurora

// AURORA. A curtain of light folded in slow air.
//
// The grammar is horizontal and nothing falls, which is the whole distance
// between this and the Liquid pack. What an aurora is, physically, is a SHEET
// seen edge on: brightness is path length through the sheet, so where the sheet
// folds back across itself the light doubles, and that doubling is the only
// place a curtain ever gets bright. There is no emission dial in this style at
// all beyond the house one, because the brightening is geometry.
//
// Two facts about a real curtain carry most of the reading, and both are in the
// vertical profile:
//
//   the lower border is SHARP. It is where the incoming particles finally run
//   out of atmosphere to hit, and it is the crispest edge in the sky.
//   the top is DIFFUSE. It fades over kilometres with nothing to end it.
//
// So the profile is a fast smoothstep up into the foot and an exponential decay
// above it. Invert those two and the thing reads as fog, which is what the first
// sketch of every aurora shader does.
//
// THREE LAMINAE, feet 0.03 uv apart, each wandering on its own pair of 1D fBm
// lanes at its own rate. They are not three curtains: they are one sheet seen
// where it folds, which is why their feet sit so close together and why their
// sum is allowed to exceed one. Where two cross, the light doubles, and the
// bright vertical concentrations that appear and slide are the folds. On a line
// this costs two hashes an octave rather than the thirty two a 3D lattice would,
// which is what makes three of them affordable at 300 pt.
//
// The rays are one octave of value noise, not fBm, and that is deliberate. Two
// octaves put ray structure under three points at 46 pt and it sparkled. One
// quintic octave is a soft undulation in the curtain's brightness, which is what
// rays look like when you are not standing under them. They lean with height,
// because a curtain's rays follow the field lines and the field lines are not
// vertical in the picture plane.
//
//   c0 fold    how far the sheet wanders vertically. Low is a calm band, high
//              is a curtain with real folds in it.
//   c1 height  the exponential scale of the top's fade. How much of the frame
//              the curtain occupies above its foot.
//   c2 wander  how fast the folds travel. The three laminae drift at different
//              rates by construction, so this never reads as one sliding image.
//   c3 thin    the sheet's cross section. High is a defined lower border and a
//              compact curtain; low is a soft aurora seen through cloud.
[[ stitchable ]] half4 mg_aurora(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float foldK = clamp(c0, 0.0, 1.0);
    float heightK = clamp(c1, 0.0, 1.0);
    float wander = clamp(c2, 0.0, 1.0);
    float thin = clamp(c3, 0.0, 1.0);

    // The sky's frame. uv.y runs down the screen, so up is negative; `up` is
    // measured the way the curtain is built, which is from its foot.
    float x = uv.x / S;
    float up = -uv.y / S;

    // The top's fade, and the lower border's softness. `thin` runs the border
    // from 0.078 uv (a soft aurora behind cloud) to 0.020 (the crisp lower edge
    // a clear night gives), and 0.020 is still four soft points at 46 pt: sharp
    // for this family, never an edge.
    float H = 0.09 + 0.22 * heightK;
    float border = 0.078 - 0.058 * thin;

    float sheet = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float lane = 4.0 + 13.0 * fi;
        // Each lamina drifts at its own rate and reads its OWN stretch of sky,
        // and the two fBm terms inside it travel in OPPOSITE directions. That is
        // the difference between a fold and a slide: two counter-moving
        // components sum to a shape that changes, while one component only
        // translates. The 0.17 offset is what stops the three laminae stacking
        // into a single mass, which is how the first cut of this read as a dome
        // rather than as a curtain.
        float xi = x + 0.17 * fi;
        float rate = (0.110 + 0.230 * wander) * (1.0 + 0.42 * fi);
        float big = mg_fbm1(xi * 3.4 + t * rate, 2, lane) * 0.115;
        float fine = mg_fbm1(xi * 7.5 - t * rate * 0.50, 2, lane + 7.0) * 0.030;
        float foot = 0.050 + 0.030 * fi + (big + fine) * (0.35 + 1.30 * foldK);

        float h = up - foot;
        // Sharp below, diffuse above. Reverse these two and the species is fog.
        float prof = smoothstep(-border, 0.0, h) * exp(-max(h, 0.0) / H);

        // THE PLEATS, and this is what makes a curtain a curtain instead of a
        // glow with a shaped foot. A hanging sheet is not evenly bright across
        // its width: where it turns edge on to the eye the path through it is
        // longest, and those turns are NARROW. So the brightness rides a ridged
        // field, 1 - |n|, whose bright lines are the zero crossings of a
        // wandering scalar. That puts four to six pleats across the disc,
        // irregularly spaced, each a soft peak about 0.06 uv wide, and the
        // squaring keeps their flanks soft so none of them is ever an edge.
        // They lean with height because a curtain's structure follows field
        // lines and field lines are not vertical in the picture plane, and each
        // set travels with its own lamina, so the three slide across each other
        // and the vertical structure is never a static comb.
        float pn = mg_fbm1(xi * 3.8 + h * 0.90 + t * rate * 0.68, 2, lane + 23.0);
        float pleat = 1.0 - min(abs(pn) * 2.2, 1.0);
        float ray = 0.62 + 0.70 * pleat * pleat;
        // The far laminae are dimmer, the way the far side of a fold is.
        sheet += prof * ray * (1.0 - 0.24 * fi);
    }

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    // The sky is not empty above the curtain: airglow, at the bottom of the
    // rail, so the disc never goes to a dead flat ink where the sheet is not.
    // The pleats spend a little of the sheet's average brightness buying their
    // structure, so the coefficient comes up to keep the curtain where it was.
    float lit = 0.055 + 0.56 * sheet;
    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.90));
    // Only the overlaps emit. sheet passes 1.0 where two laminae cross, and the
    // cube makes that crossing the only thing on screen that glows.
    float3 em = mg_shade(pal, 0.80) * (0.30 * pow(max(sheet - 0.55, 0.0), 2.0)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.58));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 3. Ember

// EMBER. The air above a warm floor.
//
// The trap in this species is the obvious one: coals that breathe. A glow that
// swells and fades is the first thing anyone writes here and it is exactly the
// pulsing luminance the family forbids, so the coals in this shader have a
// brightness that does not depend on `time` at ALL. What moves is the air, and
// the air moves in three ways that are each a coordinate being read differently:
//
//   the shimmer   hot air refracts, so the sightline bends. The bed and the
//                 plume are both sampled at x + dx where dx is a slow field
//                 growing with height, because there is no bending in the first
//                 millimetre above a floor and plenty of it higher up. The
//                 coals appear to swim; the coals do not move.
//   the rise      the plume's domain scrolls DOWN in height as t grows, which
//                 carries its structure up. This is the Liquid pack's fall
//                 inverted, and it is the only place in the Light pack where
//                 the vertical motion is the subject.
//   the spread    a buoyant plume widens as it climbs, so the horizontal
//                 frequency is divided by (1 + spread h). Without it the column
//                 reads as a scrolling texture in a box rather than as gas
//                 leaving a fire.
//
// The bed is a FIELD and not a ramp: patches of noise confined near the floor
// line by an exponential, so some coals are hot and some are not, the way a bed
// of embers actually looks. A vertical gradient dimmed at the top would have
// been half the code and would have failed the first rule in the spec.
//
//   c0 heat      how far the column carries. This is the plume's exponential
//                reach, so it is the difference between a low bed of coals and
//                a fire with a real thermal above it.
//   c1 shimmer   refraction amplitude. The single most legible dial at 20 pt.
//   c2 floor     where the floor sits in the circle and how thick the bed is.
//   c3 updraft   how fast the air leaves and how vertically stretched it gets
//                on the way. Fast and stretched reads as a draught; slow and
//                compact reads as still air over dying coals.
[[ stitchable ]] half4 mg_ember(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float heat = clamp(c0, 0.0, 1.0);
    float shimmer = clamp(c1, 0.0, 1.0);
    float floorK = clamp(c2, 0.0, 1.0);
    float updraft = clamp(c3, 0.0, 1.0);

    // The floor sits low in the circle. uv.y runs down, so a pixel above the
    // floor has a smaller y and a positive height.
    float floorY = 0.16 + 0.12 * floorK;
    float x = uv.x / S;
    float h = (floorY - uv.y) / S;

    // THE SHIMMER. Two octaves at f = 2.1 is a broad, slow warp: fine warp
    // detail here would tear the coals into speckle instead of making them swim.
    // It grows from nothing at the floor, because air that has not risen yet has
    // not had time to bend anything.
    float3 wp = float3(x * 2.1, h * 1.7 - t * (0.55 + 0.95 * updraft), t * 0.30);
    float warp = mg_fbm3(wp, 2, 2.03, 0.5);
    float dx = warp * (0.030 + 0.080 * shimmer) * smoothstep(0.0, 0.32, h);
    float xs = x + dx;

    // THE BED. Patches, not a ramp. Its own slow crawl in the third axis is the
    // coals shifting as they burn down, and it is the only motion the light
    // itself has: about a fifteenth of the plume's rate, which is felt and not
    // watched. It took the smaller half of the tempo lift for that reason. Coals
    // that reorganise as fast as the gas above them stop reading as fuel.
    float3 bp = float3(xs * 2.8, h * 1.2, t * 0.115);
    float bed = 0.5 + 0.5 * mg_fbm3(bp, 3, 2.03, 0.5);
    float bedThick = 0.050 + 0.060 * floorK;
    float bedMask = smoothstep(-0.085, -0.004, h) * exp(-max(h, 0.0) / bedThick);

    // THE PLUME. Domain scrolls down so structure travels up; horizontal
    // frequency opens with height so the column widens as it climbs.
    float spread = 1.0 + (0.85 + 1.55 * updraft) * max(h, 0.0);
    float3 pp = float3(xs * (2.6 / spread),
                       h * (2.30 - 0.80 * updraft) - t * (0.94 + 1.55 * updraft),
                       t * 0.195);
    float plume = 0.5 + 0.5 * mg_fbm3(pp, 3, 2.03, 0.5);
    float column = exp(-max(h, 0.0) / (0.16 + 0.40 * heat));
    // Only the hot part of the plume carries light. The smoothstep is what turns
    // a uniform column of noise into separate tongues of warm gas.
    float rise = column * smoothstep(0.32, 0.86, plume);

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float coals = bedMask * (0.30 + 0.62 * bed);
    float lit = 0.045 + 0.86 * coals + (0.20 + 0.34 * heat) * rise;
    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.90));
    // Only the coals themselves emit. Gas glowing as hard as the fuel is what
    // makes a fire shader read as a cartoon.
    float3 em = mg_shade(pal, 0.80) * (0.55 * pow(coals, 2.6)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.58));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 4. Lantern

/// The fog, as one law that the pixel, the lamp and the four march samples all
/// read, so the medium is the same medium everywhere in the picture.
///
/// THE SHAPE OF IT IS THE WHOLE FIX. The first cut of this style used an evenly
/// dense fog, and an evenly dense fog is worthless here: the optical depth along
/// a path is then just the mean density times the path LENGTH, so exp(-ext tau)
/// is a smooth function of distance from the lamp, the shadow term collapses
/// into a second inverse-square falloff, and the render comes out as a bare
/// radial gradient with the medium nowhere in it. That is exactly what it did.
///
/// So the density is a thin even haze with sparse THICK WISPS drifting through
/// it, and the smoothstep is what makes them sparse: below 0.40 of the noise
/// range there is only haze, and the wisp term climbs from there. The mean stays
/// low, so path length contributes little, while crossing a wisp costs several
/// times a clear path. Now the optical depth answers to WHAT the light passed
/// through rather than to how far it came, the shadows are shaped like the fog,
/// and they sweep as it drifts.
///
/// The domain is compressed 2.2x across, because fog in still air lies in
/// horizontal sheets, and the anisotropy is a second reason nothing here ever
/// comes out circular.
static inline float mg_fog(float2 p, float2 flow, float ff, float fz, float fogK) {
    float2 q = (p + flow) * float2(ff / 2.2, ff);
    float n = 0.5 + 0.5 * mg_fbm3(float3(q, fz), 2, 2.03, 0.5);
    return (0.16 + 0.30 * fogK) + (0.55 + 1.45 * fogK) * smoothstep(0.40, 0.95, n);
}

// LANTERN. One light behind moving fog.
//
// This is the style the family law was written for, so it is worth being exact.
// The lamp's power is a CONSTANT. It appears in the code once, it is never
// multiplied by anything derived from `time`, and if the fog were removed the
// picture would be a still image. Every bit of life on screen comes from the
// medium sliding in front of the light. A lantern that throbs is a novelty; a
// lantern whose fog is moving is a lantern.
//
// The model is single scattering, which is the honest one and also the cheap
// one. The eye sees the fog AT the pixel, lit by the lamp, dimmed by whatever
// fog stands between:
//
//     L(p) = rho(p) * Lamp(|p - lamp|) * exp(-ext * integral of rho from lamp to p)
//
// The integral is four samples along the line from the pixel toward the lamp,
// which with the pixel's own density and the lamp's own is six field taps and
// the whole budget of this style. What that integral buys is the thing that
// makes the picture: a thick wisp standing between the lamp and one side of the
// frame throws a soft SHADOW across it, and as the fog drifts those shadows
// sweep. Nothing in the frame is drawn as a ray and there is not a single hard
// edge anywhere, and yet the light visibly comes from a place. It only works
// because the fog is lumpy, which is the point mg_fog above is making.
//
// The lamp is never drawn. There is no disc, no core, no falloff sprite: the
// brightest pixel on screen is bright because the fog is dense THERE, so the
// centre of the glow wears the fog's own shape and can never resolve into an
// orb. Watch the middle of it drift off round as a wisp crosses. That is the
// species.
//
//   c0 fog     density and extinction together, and it moves both the haze
//              floor and the wisps. Low is a clear night with a lamp a long way
//              off and only a suggestion of structure; high is weather, where
//              the light barely gets out of its own halo and the shadows across
//              it are the loudest thing in the frame.
//   c1 reach   how far the light carries: the softening radius of the inverse
//              square. This is also the dial that decides whether the indicator
//              reads as one presence or as a lit field.
//   c2 drift   how fast the fog crosses and turns over.
//   c3 offset  how far the lamp sits off centre. At 0 it is dead centre, which
//              is the least interesting composition and is not the default.
[[ stitchable ]] half4 mg_lantern(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float fogK = clamp(c0, 0.0, 1.0);
    float reach = clamp(c1, 0.0, 1.0);
    float driftK = clamp(c2, 0.0, 1.0);
    float offset = clamp(c3, 0.0, 1.0);

    // The lamp. Up and to the left, because a light source placed on the
    // diagonal reads as a place in a room and a centred one reads as a target.
    // Its position does not scale with formScale: it is a location, not a form.
    float2 lamp = float2(-0.155, -0.115) * offset;

    // The fog's frame. Two octaves at f = 4.6 puts the finest cell at 0.11 uv,
    // which is eight points across in the gallery's 76 pt cell: a wisp whose
    // shape you can actually see. Finer than this and the medium turns back into
    // an even grey, which is the failure this style already had once.
    // The drift took the full 2x of the tempo pass and the turnover took 1.6x,
    // and this style is where that split matters most: the lamp is forbidden to
    // change, so the fog crossing in front of it is the ONLY thing that can make
    // the indicator read as active. Fog that crosses faster reads as faster;
    // fog that boils faster just reads as weather.
    float2 flow = float2(0.144, -0.052) * t * (0.32 + 1.30 * driftK);
    float ff = 4.6 / S;
    float fz = t * (0.072 + 0.240 * driftK);

    // The density HERE, which is the thing the eye is actually looking at, and
    // the density AT THE LAMP, which is the thickness the light has to get out
    // of before it can light anything at all.
    float rho0 = mg_fog(uv, flow, ff, fz, fogK);
    float rhoL = mg_fog(lamp, flow, ff, fz, fogK);

    // The occlusion between the lamp and here. Four samples, and the fixed count
    // is the point: the loop bound never depends on the distance to the lamp, so
    // a pixel in the corner costs exactly what a pixel at the centre costs.
    float2 ray = lamp - uv;
    float len = length(ray);
    float tau = 0.0;
    for (int i = 1; i <= 4; i++) {
        float s = (float(i) - 0.5) * 0.25;
        tau += mg_fog(uv + ray * s, flow, ff, fz, fogK);
    }
    tau *= len * 0.25;
    float shade = exp(-(2.4 + 5.0 * fogK) * tau);

    // THE LAMP'S POWER, and this is the constant the whole style rests on. The
    // softening radius keeps the inverse square finite at the source, and it is
    // generous on purpose: a tight core would resolve into the orb this family
    // bans, and a broad one leaves the fog's own structure as the only thing
    // shaping the middle of the glow.
    float sig = (0.075 + 0.150 * reach) * S;
    float dist2 = dot(uv - lamp, uv - lamp);
    float lampL = (sig * sig) / (dist2 + sig * sig);

    // THE PASSING THICKNESS. When a wisp drifts across the lamp itself, less
    // light leaves the source at all and the whole picture eases down for a few
    // seconds. This is the only global dimming anywhere in the pack, and it is
    // still not a brightness animation: the lamp's power does not move, rhoL
    // does, and rhoL is a coordinate being read. The coefficient is small on
    // purpose, about a fifth at the very thickest, because a lantern going dark
    // is an EVENT and this family does not have events.
    float escape = exp(-(0.10 + 0.12 * fogK) * rhoL);

    // What the eye sees: the fog here, lit by the lamp, shadowed by whatever fog
    // stands between, and eased by whatever sits on the lamp. The second term is
    // the multiply-scattered haze that survives where the direct path is
    // blocked, and it carries the local density too, because scattered light
    // still needs something to scatter off. Without it the shadows read as holes
    // cut in the picture rather than as shadow.
    float lit = rho0 * lampL * escape * (0.14 + 0.86 * shade) * 1.30
              + 0.15 * lampL * sqrt(lampL) * (0.25 + 0.75 * rho0);

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float3 body = mg_shade(pal, clamp(0.05 + 1.05 * lit, 0.0, 0.90));
    float3 em = mg_shade(pal, 0.80) * (0.50 * pow(clamp(lit, 0.0, 1.0), 2.2)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.60));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 5. Mirage

// MIRAGE. Layered air bending a distant light.
//
// THERE IS A SUBJECT, and the first cut of this did not have one. It windowed a
// field into a band across the whole frame, which meant the picture was a bar of
// light, the bands were bars of light, and the render came out as a smeared
// loading indicator. A mirage is not made of bands. A mirage is a LIGHT, and
// bands of air that bend its image.
//
// So there is now a small, compact, off-centre source sitting just above the
// horizon, and everything else in this style is optics performed on its image.
// The bands are never drawn. You see them only in what they do to the light,
// which is the honest way and also the only way this reads as refraction.
//
// THE OPTICS. A mirage is a one-dimensional remapping of the vertical angle: the
// row of screen at height d shows whatever the far field holds at height ys(d),
// and everything interesting follows from the shape of that one function.
//
//     ys(d) = fold(d) + A * band(x, d, t) * grip(d)
//
//   the fold      above the inversion ys runs straight; below it the map turns
//                 over to -d * m, so the eye receives the SECOND, INVERTED image
//                 that makes a hot road look wet. m > 1 squashes that copy,
//                 which is what distance does to it. The two branches are
//                 blended over a narrow band so the map stays C1 and the seam is
//                 never an edge.
//   the bands     the layered air, stretched wide and squeezed tall, sliding
//                 sideways with time. Where its slope makes ys non-monotone the
//                 image FOLDS again: a slice of the light appears twice, once
//                 the right way up and once inverted, which is the stacking and
//                 tearing a distant car does over summer tarmac.
//   the grip      refraction is a hot-layer phenomenon, so it is zero above the
//                 horizon and full below. The top of the light therefore stays
//                 clean while its bottom stretches and breaks up, which is what
//                 a real one looks like and is most of the composition.
//
// A IS LOAD-BEARING AND IT WAS THE BUG. The image only folds where |A * dband/dd|
// passes 1, which with the band's vertical frequency near 8 needs A above about
// 0.125. The first cut set it at 0.038, well under the threshold, so the map
// stayed monotone, nothing ever doubled, and no refraction structure was visible
// at any size. It sits at 0.155 now, which puts the strongest strata just past
// folding at the default and every stratum past it with `bend` up. If this ever
// reads flat again, that number is the one to check first.
//
//   c0 bands     how finely the air is stratified: two thick layers across the
//                light, or four thin ones.
//   c1 bend      the displacement amplitude, which is the fold threshold above.
//                Low is a still hot day where the light only wavers; high is the
//                road boiling and the image coming apart in slices.
//   c2 distance  how far away the light is. Far is small and tight with a
//                hard-squashed mirror sitting close under it; near is broad and
//                open with the two images well separated. The dial that changes
//                the composition most.
//   c3 haze      the veiling glare lying in the hot layer, carrying the bands'
//                own density so the strata stay faintly legible away from the
//                light. Without some of it the frame reads as a lamp in a void.
[[ stitchable ]] half4 mg_mirage(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float bands = clamp(c0, 0.0, 1.0);
    float bend = clamp(c1, 0.0, 1.0);
    float dist = clamp(c2, 0.0, 1.0);
    float haze = clamp(c3, 0.0, 1.0);

    // The horizon sits a little above centre so the road has room. It is fixed
    // in the circle; only the field's scale answers to formScale.
    const float hor = -0.055;
    float x = uv.x / S;
    float d = (uv.y - hor) / S;          // positive below the horizon, on the road

    // THE LAYERS. Stretched wide and squeezed tall, travelling sideways with
    // time. The vertical frequency is what decides how many strata cross the
    // light: at 8.0 the finest octave's cell is 0.062 uv, which puts two to four
    // of them over the source's own height and sits right on this pack's scale
    // floor. Two octaves and no more, because horizontal strata are the first
    // thing in the pack that would alias. The 1.6 across is deliberately enough
    // to vary within the light's width, so a stratum SHEARS the image instead of
    // sliding all of it together.
    float3 bp = float3((x + t * 0.170) * 1.6, d * (5.5 + 5.0 * bands), t * 0.255);
    float band = mg_fbm3(bp, 2, 2.03, 0.5);

    // THE FOLD, and then THE BEND, which together are the whole mapping.
    float m = 1.20 + 0.90 * dist;
    float mirror = smoothstep(-0.025, 0.040, d);
    float yy = mix(d, -d * m, mirror);
    float grip = smoothstep(-0.055, 0.115, d);
    float ys = yy + band * (0.075 + 0.160 * bend) * grip;

    // THE LIGHT. Small, compact and off to the left, because a source on the
    // axis reads as a target and this wants to read as something a long way down
    // a road. Its position is in the circle's own frame and does not scale, the
    // way the lantern's lamp does not: it is a place, not a form.
    const float sx = -0.115;
    const float sy = -0.062;
    float wx = 0.090 + 0.050 * (1.0 - dist);
    float wy = 0.070 + 0.050 * (1.0 - dist);
    float gx = (x - sx) / wx;
    float gy = (ys - sy) / wy;
    float core = exp(-(gx * gx + gy * gy));
    float halo = exp(-0.30 * (gx * gx + gy * gy));

    // The light is not a smooth blob. Two octaves of slow field give it internal
    // structure, so at 300 pt there is something to look at inside it and the
    // slices the bands cut off it are not all identical. This is the subject and
    // not the medium, so it took the smallest lift in the pack: a light a long
    // way down a road does not change quickly, and the shimmer crossing it is
    // where all the speed belongs.
    float3 sp = float3(x * 3.2, ys * 3.2 + 5.7, t * 0.065);
    float grain = 0.5 + 0.5 * mg_fbm3(sp, 2, 2.03, 0.5);

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float img = core * (0.42 + 0.78 * grain);
    // The hot layer's veiling glare: the one place the strata are visible in
    // their own right rather than through what they do to the light, which is
    // why it carries the band field. It is gated in BOTH axes, and the
    // horizontal gate is the important one: glare belongs around its source, and
    // an ungated version of this is a faint bar across the whole frame, which is
    // the exact shape this style was rebuilt to stop being.
    float veil = exp(-(ys * ys) / (0.145 * 0.145)) * exp(-0.18 * gx * gx)
               * haze * 0.24 * (0.45 + 0.55 * (0.5 + 0.5 * band));
    float lit = 0.030 + 0.95 * img
              + 0.24 * halo * (0.40 + 0.60 * (0.5 + 0.5 * band))
              + veil;

    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.90));
    float3 em = mg_shade(pal, 0.80) * (0.45 * pow(clamp(img, 0.0, 1.0), 2.2)) * max(glow, 0.0);

    // Pulled in tighter than the rest of the pack. The old bar ran the full
    // width and its ends were still lit where the clip landed; a compact source
    // does not need the room, so it does not get it.
    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.52));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - The arc

/// THE APERTURE LAW, written in the shape of the pour's pv_exhale_law: state
/// the motion as a law, take the position as its exact integral, and never let a
/// frame depend on the frame before it. Sample it at any t at all, from a
/// screenshot rig or a scrubbed slider or an app resumed from the background,
/// and it lands exactly where the animation would have been.
///
/// The law is relaxation. What is left to open closes on itself at a rate
/// proportional to how much is left, which is the same differential equation as
/// a breath being let out and the same one every settling thing in this house
/// obeys:
///
///     c'(tau) = -k c(tau),   c(0) = 1     so   c(tau) = e^(-k tau)
///     open(tau) = 1 - c(tau)              the exact integral of k e^(-k tau)
///
/// k is 3 / openTime rather than 1 / openTime so the dial means what it says: at
/// tau = openTime the aperture is within five per cent of open, which is the
/// instant a person would call it arrived. Returns (open, speed, remaining),
/// where `remaining` is the still-opening fraction the way pv_exhale_law's third
/// component is the still-moving one.
///
/// Note what the law does NOT do: it does not keep a floor of motion, the way
/// the exhale's speed does. An aperture that kept opening forever would leave
/// the frame. The whisper of life at rest belongs to the medium instead, which
/// is the honest place for it: the air in the beam and the torn lip of the
/// opening go on drifting after the opening itself has arrived.
static inline float3 mg_open_law(float tau, float openTime) {
    float T = max(openTime, 0.50);
    float k = 3.0 / T;
    float e = exp(-k * max(tau, 0.0));
    return float3(1.0 - e, k * e, e);
}

// MARK: - 6. Oculus

// OCULUS. A soft aperture admitting light, opening as the thought completes.
//
// The arc style of this pack, and the one with the most obvious way to fail: an
// aperture is a round hole, the indicator is a round hole, and a lazy version of
// this is a glowing ball inside a circle, which is the fibonacci dot sphere the
// whole package exists to not be. Four things keep it an opening:
//
//   the edge is TORN. Its radius is a noise field evaluated on the unit circle,
//   which is periodic in the angle by construction and so has no seam at the
//   wrap. About seven bays around the rim at the base octave, wandering. It is
//   never a circle at any instant.
//   the light LEANS. What comes through an oculus comes from a direction, so the
//   interior brightens toward the upper left and falls away opposite. A radially
//   symmetric interior is what makes a hole look like a ball.
//   the interior has STRUCTURE. Two octaves of slow field, so the admitted light
//   is a piece of sky and not a fill.
//   the beam is made of AIR. The glow outside the opening is the interior light
//   carried into the medium and multiplied by a fine drifting field, so its
//   falloff is textured rather than smooth. That texture is `dust`, and it is a
//   density, never motes: the frequency is held low enough that at 46 pt the
//   finest structure is over three points across and reads as air.
//
// THE ARRIVAL. tau is measured from `epoch` and the aperture opens on
// mg_open_law over 2.6 s, which is about the length of a thought that has
// finished. The still-opening fraction does one extra job while it lasts: the
// lip is more agitated during the opening and settles as it arrives, so a
// photograph at half a second and a photograph at eight are visibly different
// pictures rather than the same picture at two offsets.
//
// The open time is deliberately NOT divided by `speed`. Like the pour's
// exhaleTime it is a number of real seconds describing an event, and it has to
// keep meaning that whatever the house tempo dial says. `speed` drives the
// medium, which is the thing that is still moving afterwards.
//
// AND AT REST IT IS STILL ALIVE. The opening arrives, the law goes quiet, and
// three fields keep drifting under it: the lip wanders, the sky inside turns,
// the air in the beam moves through. Nothing pulses. Settled here is a whisper,
// which is what the family asks for and what a frozen frame would not give.
//
//   c0 aperture  the rest radius of the opening.
//   c1 rim       how much light the material's own lip catches, and how defined
//                that lip is. High is stone with an edge; low is an opening in
//                something soft.
//   c2 beam      how far the admitted light carries into the medium outside.
//   c3 dust      how much fine air-structure the light shows. A density, and
//                the frequency is capped so it can never resolve into specks.
[[ stitchable ]] half4 mg_oculus(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float apertureK = clamp(c0, 0.0, 1.0);
    float rimK = clamp(c1, 0.0, 1.0);
    float beamK = clamp(c2, 0.0, 1.0);
    float dustK = clamp(c3, 0.0, 1.0);

    // THE ARC. Real seconds, measured from the epoch the view hands in.
    float tau = max(time - epoch, 0.0);
    float3 law = mg_open_law(tau, 2.6);

    float r = length(uv);
    float ang = atan2(uv.y, uv.x);

    // The rest radius, and the seam it opens from. R0 is not zero: an aperture
    // that starts fully shut starts as a black disc, and a thinking indicator
    // that begins as nothing has a frame where it looks broken.
    float Rrest = (0.100 + 0.150 * apertureK) * S;
    float R = mix(0.022 * S, Rrest, law.x);

    // THE TORN LIP. Sampled on the unit circle, so it is periodic in the angle
    // with no wrap seam anywhere. f = 1.1 puts about seven bays around the rim
    // at the base octave; the second octave doubles that at a quarter of the
    // amplitude, which is a torn edge rather than a scalloped one. The third
    // axis is the wander that keeps this alive after the opening has arrived.
    float2 ring = float2(cos(ang), sin(ang)) * 1.10;
    float tearN = mg_fbm3(float3(ring, t * 0.234), 2, 2.03, 0.5);
    // Agitated while it opens, settled when it has. The 0.30 is the only place
    // the arc touches anything but the radius.
    float Ra = R * (1.0 + (0.16 + 0.30 * law.z) * tearN);

    // THE EDGE. Soft by default; `rim` tightens it toward a defined lip.
    float w = (0.050 + 0.085 * (1.0 - rimK)) * S;
    float pass = 1.0 - smoothstep(Ra - w, Ra + w, r);

    // THE LEAN. Light through an opening comes from somewhere.
    const float2 dir = float2(-0.55, -0.835);
    float lean = 0.58 + 0.42 * smoothstep(-Rrest, Rrest, dot(uv, dir));

    // THE SKY BEYOND. Two octaves at f = 6.5 puts the finest cell at 0.076 uv,
    // three and a half points at 46 pt: structure in the light, not grain.
    float3 ip = float3(uv * (6.5 / S) + float2(0.0, -t * 0.170), t * 0.15);
    float inner = 0.5 + 0.5 * mg_fbm3(ip, 2, 2.03, 0.5);

    // THE AIR. f = 7.0 over two octaves is the finest field in this pack and it
    // sits exactly on the scale rule: 0.070 uv, three points at 46 pt. Anything
    // finer becomes motes, and motes are the one thing this package must never
    // draw.
    float3 ap = float3(uv * (7.0 / S) + float2(t * 0.044, -t * 0.116), t * 0.285);
    float air = 0.5 + 0.5 * mg_fbm3(ap, 2, 2.03, 0.5);
    air = 1.0 - dustK * 0.55 * (1.0 - air);

    // THE BEAM. The admitted light carried outward through the air. Exponential,
    // so it has no end anywhere; textured, so it has no smooth halo either.
    float beam = exp(-max(r - Ra, 0.0) / ((0.045 + 0.115 * beamK) * S)) * air;

    // THE LIP. A band of the material's own edge catching the light, sitting
    // just OUTSIDE the opening and brighter on the lit side. Gaussian, and never
    // a full ring, because a closed bright ring is a drawn shape and this family
    // does not draw shapes.
    float lipW = (0.028 + 0.040 * rimK) * S;
    float lg = (r - Ra * 1.05) / lipW;
    float lip = exp(-lg * lg) * rimK * lean;

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float through = pass * lean * (0.42 + 0.58 * inner);
    float spill = beam * (0.35 + 0.65 * lean);
    float lit = 0.04 + 0.84 * through + 0.30 * spill + 0.34 * lip;
    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.92));
    float3 em = mg_shade(pal, 0.80) * (0.55 * pow(clamp(through, 0.0, 1.0), 2.0)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.60));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 7. Dapple

// DAPPLE. Canopy light, and the shade breathing across the floor.
//
// The mechanism is two layers of leaves, and it is the whole species. A canopy
// is not one screen with holes in it, it is a DEPTH of overlapping crowns, and
// light reaches the floor only where a gap in the near layer happens to line up
// with a gap in the far one. So the transmission here is a PRODUCT of two
// thresholded fields drifting at different rates and in different directions,
// and everything good about the picture follows from that product:
//
//   the patches are broad and irregular, because the intersection of two soft
//   regions is a soft region, and nothing in it is ever a cell or a dot
//   they appear and vanish where they are, rather than sliding in from the
//   edge, because two gaps come into alignment in place
//   and that is the BREATHING. Nothing here modulates brightness with time. The
//   shade breathes because the two layers are sliding past each other, which is
//   a coordinate being read, which is the family law
//
// Two layers and not three. Three would be more literally true of a real
// canopy, but the intersection of three random gap sets is small and scattered,
// and small scattered bright things are exactly the dots this package exists to
// avoid. The large scale comes from a separate broad crown field instead, which
// lifts and dims whole regions of floor without ever fragmenting them.
//
// WHY THE PATCHES ARE ROUND, which is the fact that makes dapple look like
// dapple. Each bright patch on a forest floor is not the shape of the gap above
// it: it is a PINHOLE IMAGE OF THE SUN, and the further the floor is from the
// canopy the more completely the gap's own shape is lost and the rounder and
// softer the patch becomes. That is what `depthLight` is. It widens the
// threshold (a wider penumbra) and lowers the canopy's effective frequency (a
// blurred projection) together, because in the real thing those are one effect.
// At zero the floor is right under the leaves and the patches wear the gaps'
// torn shapes; at one it is a long way below and they are soft warm ovals.
//
// This is the pack's other water-and-light style and it must never be confused
// with mg_caustic, so the two are built to be opposites: the caustic is a FINE
// WEB drawn as the zero set of a Jacobian, all line and no area; the dapple is
// BROAD AREA with no line in it anywhere.
//
//   c0 canopy      how fine the leaf mass is. Low is a few big crowns, high is
//                  a dense canopy with small gaps.
//   c1 breeze      how much the canopy moves: the layers' drift and the gust
//                  that sways them. The gust is positional, never luminous.
//   c2 patch       how open the canopy is, which is the threshold the gaps are
//                  cut at, which is how much floor is lit and how large the
//                  patches get.
//   c3 depthLight  how far the floor is below the leaves. The penumbra dial
//                  described above, and the one that decides whether this reads
//                  as leaf shadow or as sunlight.
[[ stitchable ]] half4 mg_dapple(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float canopy = clamp(c0, 0.0, 1.0);
    float breeze = clamp(c1, 0.0, 1.0);
    float patch = clamp(c2, 0.0, 1.0);
    float fall = clamp(c3, 0.0, 1.0);

    // THE PENUMBRA, both halves of it. A wider threshold is a softer shadow
    // edge; a lower frequency is the gap's own shape being lost on the way
    // down. They move together because in the real thing they are one effect.
    float soft = 0.10 + 0.30 * fall;
    float blur = 1.0 - 0.28 * fall;

    // THE TWO LAYERS. The far one projects larger and drifts the other way, so
    // the alignments come and go rather than travelling across the frame.
    float trans = 1.0;
    for (int i = 0; i < 2; i++) {
        float fi = float(i);
        // At canopy 1 with the floor right under the leaves this reaches 7.6,
        // whose finest octave cell is 0.065 uv: the top of the legal range for
        // a two octave field and still three points at 46 pt.
        float freq = (4.6 + 3.0 * canopy) * blur * (1.0 - 0.34 * fi) / S;
        float2 dr = mix(float2(0.085, 0.032), float2(-0.055, 0.024), fi)
                  * t * (0.40 + 1.40 * breeze);
        // THE GUST. Two incommensurate sines per layer, so the sway never finds
        // a beat and never reads as a wobble on a timer. It moves the canopy's
        // COORDINATE. A gust that changed how much light came through would be
        // the pulsing this family forbids; a gust that moves the leaves is what
        // actually happens.
        float2 gust = float2(sin(t * (0.83 - 0.21 * fi) + fi * 2.3),
                             cos(t * (0.61 + 0.17 * fi) + fi * 1.1))
                    * (0.012 + 0.045 * breeze);
        float3 q = float3((uv + dr + gust) * freq, t * (0.17 - 0.05 * fi));
        float n = mg_fbm3(q, 2, 2.03, 0.5);
        // The gap: light passes where the leaf field is thin. `patch` moves the
        // cut, so it opens and closes the canopy without changing its scale.
        float cut = 0.16 - 0.26 * patch;
        trans *= smoothstep(cut - soft, cut + soft, n);
    }

    // THE CROWN. The canopy's large scale thickness, drifting slowly on its own.
    // It lifts and dims whole stretches of floor at once, which is the scale a
    // third multiplied layer would have destroyed rather than provided.
    float3 cq = float3((uv + float2(0.020, 0.008) * t * (0.40 + 1.40 * breeze)) * (1.35 / S),
                       t * 0.075);
    float crown = 0.5 + 0.5 * mg_fbm3(cq, 2, 2.03, 0.5);

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    // Shade under a canopy is never black: it is filled with light bounced off
    // every leaf and trunk around it, and a dapple whose shade goes to ink reads
    // as spotlights on a stage instead of as a wood.
    float lit = (0.050 + 0.130 * crown) + (0.58 + 0.32 * crown) * trans;
    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.90));
    // Only the fully aligned gaps carry the sun itself. The cube is what keeps
    // the emission on the few brightest patches rather than on all of them.
    float3 em = mg_shade(pal, 0.80) * (0.50 * pow(clamp(trans, 0.0, 1.0), 3.0)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.60));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 8. Eclipse

// ECLIPSE. A soft dark mass wandering across a light, and the corona at its limb
// doing all of the talking.
//
// THE READING OF THE BRIEF, stated so it can be checked. "Never fully covered
// and never fully free" is taken here to mean the PICTURE is always partial:
// there is always corona, so the light is never extinguished, and there is
// always a dark mass, so the light is never simply a light. The occluder's
// wander is bounded to guarantee both. It is a closed path around the light
// rather than a pass across it, which is also why this has no beginning and no
// end and therefore no arc: `epoch` is ignored.
//
// THE INVERSION, which is how this stays clear of its two neighbours at 76 pt.
// mg_oculus is bright in the middle with a dark surround. mg_lantern is a glow
// with no dark anywhere in it. This one is DARK IN THE MIDDLE with its light at
// the edge, which is the opposite composition to both, and the difference
// survives being shrunk to a gallery cell because it is a difference of where
// the black is rather than of what the texture does.
//
// THE CORONA IS NOT A RING, and three things stop it becoming one:
//
//   its reach is a function of ANGLE. The falloff length outside the limb is
//   modulated by a field evaluated on the unit circle, so the corona goes out in
//   plumes of very different lengths and its outer boundary is ragged. A corona
//   with one falloff length is an annulus, and an annulus is a graphic.
//   it is weighted by the LIGHT BEHIND IT. The occluder is offset from the
//   light, so one side of its limb has the light's bright middle behind it and
//   the opposite side has only the light's outskirts. That makes the corona
//   several times brighter on one side, which is the crescent, and it costs
//   nothing because the light field is already in hand.
//   the limb itself is TORN and soft, and it drifts.
//
// The occluder is never black either. A mass lit only by scattered light is
// still a mass; a mass at zero is a hole cut in the picture, and the eye reads
// the hole's edge as a drawn curve no matter how soft it is.
//
//   c0 occlude   how much of the light the mass takes: its radius and how far
//                it wanders. More coverage is more limb against bright light,
//                so more corona, which is why an eclipse gets more dramatic
//                rather than dimmer as it deepens.
//   c1 corona    the corona's brightness and how far its plumes reach.
//   c2 drift     how fast the mass travels its path, which is the rate at which
//                the bright crescent swings around the limb.
//   c3 softness  how soft the mass's edge is, and how much it is allowed to
//                move. This is the dial that decides between an object passing
//                in front of a light and a thickening in the same medium.
[[ stitchable ]] half4 mg_eclipse(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float occK = clamp(c0, 0.0, 1.0);
    float coronaK = clamp(c1, 0.0, 1.0);
    float driftK = clamp(c2, 0.0, 1.0);
    float softK = clamp(c3, 0.0, 1.0);

    // THE LIGHT. Broad, structured and a little off centre. It is wide on
    // purpose: the corona is weighted by whatever light stands behind the limb,
    // and a tight source would leave the far side of the limb with nothing
    // behind it at all and the corona would read as half a ring.
    const float2 lp = float2(0.030, -0.022);
    float sigL = 0.210 * S;
    float2 dl = uv - lp;
    float3 lq = float3(uv * (5.5 / S) + float2(0.0, -t * 0.060), t * 0.12);
    float lgrain = 0.5 + 0.5 * mg_fbm3(lq, 2, 2.03, 0.5);
    float lightRaw = exp(-dot(dl, dl) / (sigL * sigL)) * (0.52 + 0.62 * lgrain);

    // THE WANDER. A closed path with incommensurate rates on the two axes, so
    // the mass never retraces the same loop and never comes to rest, and its
    // offset from the light stays inside a band by construction: it cannot
    // leave the light and it cannot centre on it.
    float th = t * (0.18 + 0.36 * driftK);
    float2 orbit = float2(cos(th), sin(th * 0.77) * 0.72) * (0.062 + 0.070 * occK) * S;
    float2 op = lp + orbit;
    float2 dO = uv - op;
    float ro = length(dO);
    float angO = atan2(dO.y, dO.x);

    // THE LIMB. Torn on the unit circle, so it is periodic in the angle with no
    // seam at the wrap, and drifting, so the edge is alive without the mass ever
    // changing size.
    float2 ring = float2(cos(angO), sin(angO)) * 1.25;
    float tearN = mg_fbm3(float3(ring, t * 0.26), 2, 2.03, 0.5);
    float Rocc = (0.115 + 0.075 * occK) * S * (1.0 + (0.07 + 0.09 * softK) * tearN);
    float w = (0.030 + 0.055 * softK) * S;
    float cover = 1.0 - smoothstep(Rocc - w, Rocc + w, ro);

    // THE PLUMES. A second field on the same circle, displaced in the plane so
    // it is a different realisation while staying periodic, driving the corona's
    // REACH rather than its brightness. That is what makes the outer edge ragged
    // instead of round.
    float2 cring = float2(cos(angO), sin(angO)) * 1.90 + float2(11.3, -7.1);
    float plumeN = 0.5 + 0.5 * mg_fbm3(float3(cring, t * 0.22), 2, 2.03, 0.5);
    float hC = (0.022 + 0.070 * coronaK) * S * (0.35 + 1.45 * plumeN);
    float limb = exp(-max(ro - Rocc, 0.0) / max(hC, 1e-4));
    // Weighted by the light standing behind this stretch of limb, which is where
    // the crescent comes from and why it swings as the mass wanders.
    float corona = limb * lightRaw * (0.85 + 1.55 * coronaK);

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    // The mass keeps a trace of scattered light so it stays a body rather than
    // a hole. The number is small enough to read as unlit and large enough that
    // the edge is a falling off and not a boundary.
    float lit = 0.028 + 0.88 * lightRaw * (1.0 - cover) + corona
              + cover * 0.050 * (0.40 + 0.60 * lgrain);
    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.90));
    float3 em = mg_shade(pal, 0.80) * (0.55 * pow(clamp(corona, 0.0, 1.0), 2.0)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.58));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

using System;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

// Invoked only by CodexBridge; never opens or renders a scene.
public static class TomXStageTwoValidation
{
    public static string Validate()
    {
        Shader shader = Shader.Find("tom/MainOpaqueX");
        if (shader == null) throw new Exception("tom/MainOpaqueX was not imported.");
        var variants = new ShaderVariantCollection();
        string[][] baseKeywords = {
            new string[] { "DIRECTIONAL" },
            new string[] { "DIRECTIONAL", "SHADOWS_SCREEN" },
            new string[] { "DIRECTIONAL", "VERTEXLIGHT_ON" },
            new string[] { "DIRECTIONAL", "LIGHTMAP_ON" },
            new string[] { "DIRECTIONAL", "FOG_LINEAR" }
        };
        string[][] addKeywords = {
            new string[] { "POINT" },
            new string[] { "POINT", "SHADOWS_CUBE" },
            new string[] { "SPOT", "SHADOWS_DEPTH" },
            new string[] { "DIRECTIONAL", "SHADOWS_SCREEN" },
            new string[] { "POINT_COOKIE" },
            new string[] { "DIRECTIONAL_COOKIE" }
        };
        try
        {
            foreach (string[] keywords in baseKeywords)
                variants.Add(new ShaderVariantCollection.ShaderVariant(shader, PassType.ForwardBase, keywords));
            foreach (string[] keywords in addKeywords)
                variants.Add(new ShaderVariantCollection.ShaderVariant(shader, PassType.ForwardAdd, keywords));
            variants.Add(new ShaderVariantCollection.ShaderVariant(shader, PassType.ShadowCaster, "SHADOWS_DEPTH"));
            variants.Add(new ShaderVariantCollection.ShaderVariant(shader, PassType.ShadowCaster, "SHADOWS_CUBE"));
            variants.WarmUp();
            var report = new StringBuilder();
            report.Append("Requested variants: ").Append(variants.variantCount)
                .Append("; warmed: ").Append(variants.isWarmedUp)
                .Append("; supported: ").Append(shader.isSupported).AppendLine();
            MethodInfo messagesMethod = typeof(ShaderUtil).GetMethod("GetShaderMessages",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static,
                null, new Type[] { typeof(Shader) }, null);
            if (messagesMethod == null) throw new Exception("Shader message inspection API unavailable.");
            Array messages = (Array)messagesMethod.Invoke(null, new object[] { shader });
            bool errors = false;
            foreach (object entry in messages)
            {
                Type type = entry.GetType();
                string severity = ReadMember(type, entry, "severity");
                report.Append(severity).Append(": ").Append(ReadMember(type, entry, "message"))
                    .Append(" at ").Append(ReadMember(type, entry, "file"))
                    .Append(":").Append(ReadMember(type, entry, "line")).AppendLine();
                errors |= severity.Equals("Error", StringComparison.OrdinalIgnoreCase);
            }
            if (errors || !shader.isSupported) throw new Exception(report.ToString());
            report.Append("No reported shader errors. This is not visual acceptance or exhaustive variant coverage.");
            return report.ToString();
        }
        finally { UnityEngine.Object.DestroyImmediate(variants); }
    }

    private static string ReadMember(Type type, object entry, string name)
    {
        FieldInfo field = type.GetField(name);
        if (field != null) return Convert.ToString(field.GetValue(entry));
        PropertyInfo property = type.GetProperty(name);
        return property != null ? Convert.ToString(property.GetValue(entry, null)) : "(unavailable)";
    }
}

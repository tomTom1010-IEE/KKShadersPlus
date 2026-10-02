using System;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;

public static class TomXStageTwoReferences
{
    private const string Root = "Assets/TomXStageTwoAcceptance";

    public static string FinishAndInspect()
    {
        string texturePath = Root + "/DiagnosticMatCap.asset";
        Texture2D matcap = AssetDatabase.LoadAssetAtPath<Texture2D>(texturePath);
        if (matcap == null)
        {
            matcap = new Texture2D(64, 64, TextureFormat.RGBA32, true, true);
            matcap.name = "DiagnosticMatCap";
            var pixels = new Color[4096];
            for (int y = 0; y < 64; y++)
            for (int x = 0; x < 64; x++)
            {
                float u = (x + .5f) / 64f;
                float v = (y + .5f) / 64f;
                float spot = Mathf.Exp(-40f * ((u-.65f)*(u-.65f) + (v-.7f)*(v-.7f)));
                pixels[y*64+x] = Color.Lerp(new Color(.15f,.2f,.25f), Color.white, spot);
            }
            matcap.SetPixels(pixels);
            matcap.Apply(true, false);
            AssetDatabase.CreateAsset(matcap, texturePath);
        }
        for (int i = 0; i < 7; i++)
        {
            var m = AssetDatabase.LoadAssetAtPath<Material>(Root + "/Materials/Layer_" + i + ".mat");
            if (m == null) throw new Exception("Missing debug material " + i);
            m.SetFloat("_ReflectionMode", 3);
            m.SetTexture("_MatCap", matcap);
            m.SetFloat("_MatCapIntensity", .3f);
            m.SetFloat("_RimStrength", .3f);
            m.SetTexture("_EmissionMask", Texture2D.whiteTexture);
            m.SetFloat("_EmissionIntensity", .1f);
            EditorUtility.SetDirty(m);
        }
        AssetDatabase.SaveAssets();
        var report = new System.Text.StringBuilder();
        Scene previous = SceneManager.GetActiveScene();
        string[] titles = { "EnvironmentOnly", "SingleLight", "MultiLight" };
        try
        {
            for (int i = 0; i < titles.Length; i++)
            {
                string path = Root + "/Scenes/" + titles[i] + ".unity";
                Scene existing = SceneManager.GetSceneByPath(path);
                if (existing.IsValid() && existing.isLoaded)
                    throw new Exception("Close the acceptance scene before automated inspection: " + path);
                Scene scene = EditorSceneManager.OpenScene(path, OpenSceneMode.Additive);
                try
                {
                    SceneManager.SetActiveScene(scene);
                    int lights = 0, renderers = 0, cameras = 0;
                    foreach (GameObject root in scene.GetRootGameObjects())
                    {
                        lights += root.GetComponentsInChildren<Light>(true).Length;
                        cameras += root.GetComponentsInChildren<Camera>(true).Length;
                        foreach (Renderer renderer in root.GetComponentsInChildren<Renderer>(true))
                        {
                            renderers++;
                            if (renderer.sharedMaterial == null || renderer.sharedMaterial.shader.name != "tom/MainOpaqueX")
                                throw new Exception("Unexpected renderer material in " + titles[i]);
                        }
                    }
                    int expectedLights = i == 0 ? 0 : i == 1 ? 1 : 3;
                    if (lights != expectedLights || cameras != 1 || renderers != (i == 0 ? 13 : 14))
                        throw new Exception("Unexpected scene contents in " + titles[i]);
                    if (RenderSettings.customReflection == null)
                        throw new Exception("Missing environment in " + titles[i]);
                    report.Append(titles[i]).Append(": lights=").Append(lights)
                        .Append(", renderers=").Append(renderers).Append(", camera=1, environment=OK; ");
                }
                finally
                {
                    if (previous.IsValid() && previous.isLoaded) SceneManager.SetActiveScene(previous);
                    EditorSceneManager.CloseScene(scene, true);
                }
            }
        }
        finally
        {
            if (previous.IsValid() && previous.isLoaded) SceneManager.SetActiveScene(previous);
        }
        return report + "Debug layers supplied with nonzero art inputs. No visual verification performed.";
    }

    public static string Create()
    {
        // Never overwrite a user's edited acceptance set on a repeated command.
        if (AssetDatabase.IsValidFolder(Root))
            throw new Exception("Acceptance folder already exists; inspect it before creating another set.");
        Shader shader = Shader.Find("tom/MainOpaqueX");
        if (shader == null) throw new Exception("X shader missing.");
        AssetDatabase.CreateFolder("Assets", "TomXStageTwoAcceptance");
        AssetDatabase.CreateFolder(Root, "Materials");
        AssetDatabase.CreateFolder(Root, "Scenes");
        Cubemap environment = CreateEnvironment();
        string[] names = { "Cloth", "Plastic", "PaintedMetal", "BareMetal", "Glossy", "SkinLike" };
        Color[] colors = { new Color(.15f,.3f,.65f), new Color(.65f,.12f,.08f),
            new Color(.12f,.5f,.22f), new Color(.65f,.5f,.25f), new Color(.2f,.3f,.6f),
            new Color(.7f,.4f,.3f) };
        float[] roughness = { .9f, .4f, .3f, .25f, .08f, .55f };
        Material[] materials = new Material[names.Length];
        for (int i = 0; i < names.Length; i++)
        {
            Material material = new Material(shader) { name = names[i] };
            material.SetColor("_BaseColor", colors[i]);
            material.SetFloat("_Roughness", roughness[i]);
            material.SetFloat("_Metallic", i == 3 ? 1f : 0f);
            material.SetFloat("_ReflectionMode", 2);
            material.SetFloat("_SpecularStrength", i == 0 ? .1f : 1f);
            material.SetFloat("_EnvironmentIntensity", i == 0 ? .2f : 1f);
            material.SetFloat("_CustomSHVolumeBlend", 0);
            material.SetFloat("_OutlineOn", 1);
            AssetDatabase.CreateAsset(material, Root + "/Materials/" + names[i] + ".mat");
            materials[i] = material;
        }
        Material[] debug = new Material[7];
        for (int i = 0; i < debug.Length; i++)
        {
            debug[i] = new Material(materials[1]) { name = "Layer_" + i };
            debug[i].SetFloat("_DebugView", i);
            AssetDatabase.CreateAsset(debug[i], Root + "/Materials/Layer_" + i + ".mat");
        }
        Scene previous = SceneManager.GetActiveScene();
        try
        {
            for (int mode = 0; mode < 3; mode++)
            {
                Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Additive);
                try
                {
                    SceneManager.SetActiveScene(scene);
                    RenderSettings.skybox = null;
                    RenderSettings.ambientMode = AmbientMode.Flat;
                    RenderSettings.ambientLight = new Color(.25f,.25f,.25f);
                    RenderSettings.defaultReflectionMode = DefaultReflectionMode.Custom;
                    RenderSettings.customReflection = environment;
                    RenderSettings.reflectionIntensity = 1;
                    RenderSettings.fog = false;
                    Camera camera = new GameObject("Acceptance Camera").AddComponent<Camera>();
                    camera.transform.position = new Vector3(0, 3.5f, -13);
                    camera.transform.LookAt(new Vector3(0, 1.5f, 0));
                    camera.clearFlags = CameraClearFlags.SolidColor;
                    camera.backgroundColor = new Color(.07f,.07f,.07f);
                    camera.renderingPath = RenderingPath.Forward;
                    camera.allowHDR = true;
                    camera.fieldOfView = 40;
                    for (int i = 0; i < materials.Length; i++)
                        Sphere(names[i], materials[i], new Vector3((i-2.5f)*1.7f, 2.2f, 0));
                    for (int i = 0; i < debug.Length; i++)
                        Sphere("Debug " + i, debug[i], new Vector3((i-3)*1.5f, .4f, 0));
                    if (mode > 0)
                    {
                        Light main = CreateLight("Directional", LightType.Directional,
                            new Vector3(0,5,-3), Color.white, 1);
                        main.transform.rotation = Quaternion.Euler(45,-30,0);
                        GameObject blocker = GameObject.CreatePrimitive(PrimitiveType.Cube);
                        blocker.name = "Shadow occluder";
                        blocker.transform.position = new Vector3(0,3,-1);
                        blocker.transform.localScale = new Vector3(.4f,2,.4f);
                        blocker.GetComponent<Renderer>().sharedMaterial = materials[0];
                    }
                    if (mode == 2)
                    {
                        CreateLight("Point", LightType.Point, new Vector3(-3,2,-2),
                            new Color(.5f,.65f,1), 2);
                        Light spot = CreateLight("Spot", LightType.Spot, new Vector3(3,4,-3),
                            new Color(1,.7f,.5f), 3);
                        spot.transform.LookAt(new Vector3(1,1,0));
                        spot.spotAngle = 65;
                    }
                    string title = mode == 0 ? "EnvironmentOnly" : mode == 1 ? "SingleLight" : "MultiLight";
                    if (!EditorSceneManager.SaveScene(scene, Root + "/Scenes/" + title + ".unity"))
                        throw new Exception("Could not save " + title);
                }
                finally
                {
                    if (previous.IsValid() && previous.isLoaded) SceneManager.SetActiveScene(previous);
                    EditorSceneManager.CloseScene(scene, true);
                }
            }
        }
        finally
        {
            if (previous.IsValid() && previous.isLoaded) SceneManager.SetActiveScene(previous);
            AssetDatabase.SaveAssets();
        }
        return "Created 3 acceptance scenes, 6 reference materials, 7 layer-debug materials and a synthetic environment cubemap at "
            + Root + ". No camera rendering or visual acceptance performed; previous active scene restored.";
    }

    private static void Sphere(string name, Material material, Vector3 position)
    {
        GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.name = name;
        sphere.transform.position = position;
        sphere.GetComponent<Renderer>().sharedMaterial = material;
    }

    private static Light CreateLight(string name, LightType type, Vector3 position, Color color, float intensity)
    {
        Light light = new GameObject(name).AddComponent<Light>();
        light.type = type;
        light.transform.position = position;
        light.color = color;
        light.intensity = intensity;
        light.range = 12;
        light.shadows = LightShadows.Soft;
        light.renderMode = LightRenderMode.ForcePixel;
        return light;
    }

    private static Cubemap CreateEnvironment()
    {
        const int size = 64;
        Cubemap cube = new Cubemap(size, TextureFormat.RGBAHalf, true);
        cube.name = "StructuredEnvironment";
        cube.wrapMode = TextureWrapMode.Clamp;
        for (int face = 0; face < 6; face++)
        {
            Color[] pixels = new Color[size * size];
            for (int y = 0; y < size; y++)
            for (int x = 0; x < size; x++)
            {
                float u = 2f * (x + .5f) / size - 1;
                float v = 2f * (y + .5f) / size - 1;
                Vector3 d;
                switch (face)
                {
                    case 0: d = new Vector3(1,-v,-u); break;
                    case 1: d = new Vector3(-1,-v,u); break;
                    case 2: d = new Vector3(u,1,v); break;
                    case 3: d = new Vector3(u,-1,-v); break;
                    case 4: d = new Vector3(u,-v,1); break;
                    default: d = new Vector3(-u,-v,-1); break;
                }
                d.Normalize();
                float spot = Mathf.Pow(Mathf.Max(0, Vector3.Dot(d, new Vector3(.4f,.5f,-1).normalized)), 40);
                float strip = Mathf.Pow(Mathf.Max(0, Vector3.Dot(d, new Vector3(-1,.2f,.4f).normalized)), 15);
                pixels[y*size+x] = new Color(.06f,.08f,.12f,1)
                    + new Color(4,3.5f,2.8f,0)*spot + new Color(.4f,.7f,1,0)*strip;
            }
            cube.SetPixels(pixels, (CubemapFace)face);
        }
        cube.Apply(true, false);
        AssetDatabase.CreateAsset(cube, Root + "/StructuredEnvironment.asset");
        return cube;
    }
}

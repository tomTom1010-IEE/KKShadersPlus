using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

public static class TomXStageTwoClosure
{
    private const string Repo = "Assets/Mods/KKShadersPlus-release1.7.1";
    private const int Size = 384;
    [Serializable] private class Shot
    {
        public string name;
        public float min, max, mean;
        public int nonFinite, litPixels;
        public double medianRenderCpuMs;
    }
    [Serializable] private class Check
    {
        public string name;
        public double difference;
        public bool passed;
    }
    [Serializable] private class Report
    {
        public string unity, device, api, colorSpace;
        public string timing = "Median synchronous Camera.Render CPU wall time; NOT GPU frame time. 4 warmup + 9 measured renders, no readback in timed section.";
        public List<Shot> shots = new List<Shot>();
        public List<Check> checks = new List<Check>();
    }

    public static string Run()
    {
        if (EditorApplication.isPlaying) throw new Exception("Exit Play Mode before regression.");
        Shader shader = Shader.Find("tom/MainOpaqueX");
        if (shader == null) throw new Exception("X shader missing.");
        int layer = FindUnusedLayer();
        Scene previous = SceneManager.GetActiveScene();
        int pixelLights = QualitySettings.pixelLightCount;
        float shadowDistance = QualitySettings.shadowDistance;
        ShadowQuality shadows = QualitySettings.shadows;
        ShadowResolution resolution = QualitySettings.shadowResolution;
        RenderTexture previousRT = RenderTexture.active;
        var previousMasks = new Dictionary<Light, int>();
        foreach (Light light in Object.FindObjectsOfType<Light>())
        {
            previousMasks.Add(light, light.cullingMask);
            light.cullingMask &= ~(1 << layer);
        }
        var temporary = new List<Object>();
        Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Additive);
        string output = Path.Combine(Directory.GetParent(Application.dataPath).FullName,
            "CodexBridge/Reports/XStageTwo-" + DateTime.UtcNow.ToString("yyyyMMdd-HHmmss"));
        Directory.CreateDirectory(output);
        var report = new Report { unity = Application.unityVersion, device = SystemInfo.graphicsDeviceName,
            api = SystemInfo.graphicsDeviceType.ToString(), colorSpace = QualitySettings.activeColorSpace.ToString() };
        var previews = new List<Color[]>();
        try
        {
            SceneManager.SetActiveScene(scene);
            QualitySettings.pixelLightCount = 8;
            QualitySettings.shadowDistance = 30;
            QualitySettings.shadows = ShadowQuality.All;
            QualitySettings.shadowResolution = ShadowResolution.High;
            RenderSettings.skybox = null;
            RenderSettings.ambientMode = AmbientMode.Flat;
            RenderSettings.ambientLight = Color.black;
            RenderSettings.fog = false;
            RenderSettings.defaultReflectionMode = DefaultReflectionMode.Custom;
            RenderSettings.customReflection = AssetDatabase.LoadAssetAtPath<Cubemap>("Assets/TomXStageTwoAcceptance/StructuredEnvironment.asset");
            Camera camera = new GameObject("Regression camera").AddComponent<Camera>();
            camera.enabled = false;
            camera.cullingMask = 1 << layer;
            camera.transform.position = new Vector3(0, 0, -3);
            camera.transform.LookAt(Vector3.zero);
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Color.black;
            camera.renderingPath = RenderingPath.Forward;
            camera.allowHDR = true;
            camera.allowMSAA = false;
            camera.orthographic = true;
            camera.orthographicSize = .7f;
            camera.nearClipPlane = .05f;
            camera.farClipPlane = 20;
            var target = new RenderTexture(Size, Size, 24, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            target.Create(); temporary.Add(target); camera.targetTexture = target;
            var readback = new Texture2D(Size, Size, TextureFormat.RGBAFloat, false, true);
            temporary.Add(readback);
            var preview = new Texture2D(Size, Size, TextureFormat.RGB24, false);
            temporary.Add(preview);
            Material m = new Material(shader); temporary.Add(m);
            m.SetColor("_BaseColor", new Color(.35f,.18f,.1f,1));
            m.SetFloat("_LightProbeBlend",0); m.SetFloat("_CustomSHVolumeBlend",0);
            m.SetFloat("_VertexLightIntensity",0); m.SetFloat("_OutlineOn",0);
            m.SetColor("_AmbientColor",new Color(.3f,.3f,.3f));
            GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            sphere.layer = layer; sphere.GetComponent<Renderer>().sharedMaterial = m;
            Light sun = NewLight(LightType.Directional, layer, new Vector3(0,2,-2));
            sun.transform.rotation = Quaternion.Euler(25,25,0);
            sun.enabled = false;
            var points = new List<Light>();
            for (int i=0;i<4;i++)
            {
                Light light = NewLight(LightType.Point,layer,new Vector3((i%2==0?-1:1)*.8f,(i<2?.7f:-.7f),-1));
                light.enabled=false; points.Add(light);
            }
            Func<string, Color[]> capture = name => {
                for(int i=0;i<4;i++) camera.Render();
                double[] times = new double[9];
                for(int i=0;i<times.Length;i++) {
                    var clock=Stopwatch.StartNew(); camera.Render(); clock.Stop(); times[i]=clock.Elapsed.TotalMilliseconds;
                }
                Array.Sort(times);
                RenderTexture.active=target;
                readback.ReadPixels(new Rect(0,0,Size,Size),0,0); readback.Apply(false);
                Color[] pixels=readback.GetPixels();
                var shot=new Shot {name=name,min=float.MaxValue,medianRenderCpuMs=times[4]};
                double total=0;
                Color[] display=new Color[pixels.Length];
                for(int i=0;i<pixels.Length;i++) {
                    Color p=pixels[i];
                    foreach(float v in new[]{p.r,p.g,p.b}) {
                        if(float.IsNaN(v)||float.IsInfinity(v)) shot.nonFinite++;
                        else {shot.min=Mathf.Min(shot.min,v);shot.max=Mathf.Max(shot.max,v);total+=v;}
                    }
                    if(Mathf.Max(p.r,Mathf.Max(p.g,p.b))>.001f) shot.litPixels++;
                    display[i]=new Color(Mathf.Clamp01(p.r),Mathf.Clamp01(p.g),Mathf.Clamp01(p.b),1);
                }
                shot.mean=(float)(total/(pixels.Length*3));
                report.shots.Add(shot);
                preview.SetPixels(display);preview.Apply(false);
                File.WriteAllBytes(Path.Combine(output,name+".png"),preview.EncodeToPNG());
                previews.Add(display);
                return pixels;
            };
            Action<string,Color[],Color[],float,float> compare=(name,a,b,multiplier,tolerance)=>{
                double difference=0;
                for(int i=0;i<a.Length;i++) {
                    difference=Math.Max(difference,Math.Abs(a[i].r*multiplier-b[i].r));
                    difference=Math.Max(difference,Math.Abs(a[i].g*multiplier-b[i].g));
                    difference=Math.Max(difference,Math.Abs(a[i].b*multiplier-b[i].b));
                }
                report.checks.Add(new Check{name=name,difference=difference,passed=difference<=tolerance});
            };
            m.SetFloat("_DebugView",1);
            Color[] body=capture("01-body-baseline");
            m.SetFloat("_SpecularIOR",2.5f);m.SetFloat("_FresnelStrength",2);
            m.SetFloat("_EnvironmentFresnelStrength",2);m.SetFloat("_Roughness",.04f);
            compare("Body invariant under reflection controls",body,capture("02-body-high-fresnel"),1,1f/255);
            m.SetFloat("_SpecularIOR",1.5f);m.SetFloat("_FresnelStrength",1);
            m.SetFloat("_ReflectionMode",2);m.SetFloat("_DebugView",3);
            m.SetFloat("_EnvironmentToonBlend",0);
            capture("03-env-continuous");
            m.SetFloat("_EnvironmentToonBlend",1);capture("04-env-toon");
            m.SetFloat("_ReflectionMode",0);m.SetFloat("_DebugView",2);
            sun.enabled=true;m.SetFloat("_SpecularStrength",1);
            sun.intensity=.5f;Color[] spec=capture("05-spec-half-light");
            sun.intensity=1;compare("Direct highlight intensity linearity",spec,capture("06-spec-full-light"),2,.003f);
            m.SetFloat("_DebugView",1);m.SetFloat("_ReflectionMode",1);m.SetFloat("_MatCapBlendMode",0);
            m.SetFloat("_MatCapIntensity",1);
            Texture2D gray=Solid(new Color(.25f,.25f,.25f,1));temporary.Add(gray);
            m.SetTexture("_MatCap",gray);
            foreach(Light light in points)light.enabled=true;
            m.SetFloat("_ReflectionMode",0);Color[] plain=capture("07-multi-body");
            m.SetFloat("_ReflectionMode",1);compare("MatCap diffuse multiply in Base and Add",plain,capture("08-multi-multiply"),.5f,.003f);
            m.SetFloat("_ReflectionMode",0);m.SetFloat("_DebugView",2);m.SetFloat("_SpecularToonBlend",0);
            Texture2D normal=new Texture2D(128,128,TextureFormat.RGBA32,true,true);temporary.Add(normal);
            Color[] normals=new Color[128*128];
            for(int y=0;y<128;y++)for(int x=0;x<128;x++) {
                float nx=.45f*Mathf.Sin(x*1.1f), ny=.45f*Mathf.Sin(y*1.3f);
                normals[y*128+x]=new Color(1,ny*.5f+.5f,1,nx*.5f+.5f);
            }
            normal.SetPixels(normals);normal.Apply(true);
            m.SetTexture("_NormalMap",normal);
            m.SetTextureScale("_NormalMap",new Vector2(3,3));
            m.SetFloat("_SpecularAA",0);capture("09-low-roughness-AA-off");
            m.SetFloat("_SpecularAA",1);capture("10-low-roughness-AA-on");
            camera.transform.position=new Vector3(.06f,0,-3);camera.transform.LookAt(Vector3.zero);
            capture("11-low-roughness-AA-on-moved");
            camera.transform.position=new Vector3(0,0,-3);camera.transform.LookAt(Vector3.zero);
            m.SetTexture("_NormalMap",null);m.SetFloat("_SpecularToonBlend",1);m.SetFloat("_DebugView",0);
            m.SetFloat("_OutlineOn",1);m.SetFloat("_CullOption",0);
            m.SetColor("_OutlineColor",new Color(0,.5f,1,1));m.SetFloat("_OutlineWidth",3);
            sphere.transform.localScale=new Vector3(1,.75f,.5f);capture("12-outline-positive-scale");
            sphere.transform.localScale=new Vector3(-1,.75f,.5f);capture("13-outline-negative-scale");
            sphere.transform.localScale=new Vector3(-1,-.75f,.5f);capture("14-outline-two-negative");
            sphere.SetActive(false);
            GameObject card=GameObject.CreatePrimitive(PrimitiveType.Quad);
            card.layer=layer;card.GetComponent<Renderer>().sharedMaterial=m;
            m.SetFloat("_OutlineOn",0);m.SetFloat("_SpecularStrength",0);
            m.SetFloat("_IndirectDiffuseIntensity",0);
            sun.enabled=false;foreach(Light light in points)light.enabled=false;
            points[0].transform.position=new Vector3(.45f,.4f,-1.5f);points[0].enabled=true;
            GameObject blocker=GameObject.CreatePrimitive(PrimitiveType.Cube);
            blocker.layer=layer;blocker.transform.position=new Vector3(.15f,.12f,-.5f);
            blocker.transform.localScale=new Vector3(.18f,.18f,.18f);
            blocker.GetComponent<Renderer>().sharedMaterial=m;
            blocker.GetComponent<Renderer>().shadowCastingMode=ShadowCastingMode.ShadowsOnly;
            Color[] shadowed=capture("15-thin-card-point-shadow");
            points[0].shadows=LightShadows.None;Color[] unshadowed=capture("16-thin-card-no-shadow");
            double delta=0;for(int i=0;i<shadowed.Length;i++)delta+=Math.Abs(shadowed[i].r-unshadowed[i].r);
            report.checks.Add(new Check{name="Point shadow changes receiver",difference=delta/shadowed.Length,passed=delta/shadowed.Length>.0001});
            blocker.SetActive(false);
            m.SetFloat("_CullOption",2);capture("17-card-cull-back");
            m.SetFloat("_CullOption",1);capture("18-card-cull-front-hidden");
            card.transform.rotation=Quaternion.Euler(0,180,0);capture("19-card-front-backface");
            m.SetFloat("_CullOption",0);capture("20-card-double-backface");
            card.transform.rotation=Quaternion.identity;capture("21-card-double-frontface");
            report.checks.Add(new Check{name="Front/back culling and flipped card visibility",
                difference=report.shots[17].litPixels,
                passed=report.shots[16].litPixels>1000 && report.shots[17].litPixels==0
                    && report.shots[18].litPixels>1000 && report.shots[19].litPixels>1000 && report.shots[20].litPixels>1000});
            int cols=4,rows=(previews.Count+cols-1)/cols;
            var sheet=new Texture2D(cols*Size,rows*Size,TextureFormat.RGB24,false);temporary.Add(sheet);
            for(int i=0;i<previews.Count;i++)sheet.SetPixels((i%cols)*Size,(rows-1-i/cols)*Size,Size,Size,previews[i]);
            sheet.Apply(false);File.WriteAllBytes(Path.Combine(output,"contact-sheet.png"),sheet.EncodeToPNG());
            File.WriteAllText(Path.Combine(output,"report.json"),JsonUtility.ToJson(report,true));
            foreach(Shot shot in report.shots)if(shot.nonFinite>0)throw new Exception("Non-finite pixels: "+shot.name+"; "+output);
            foreach(Check check in report.checks)if(!check.passed)throw new Exception("Pixel check failed: "+check.name+"; "+output);
            return "Rendered "+report.shots.Count+" regression captures; pixel assertions passed. Results: "+output;
        }
        finally
        {
            RenderTexture.active=previousRT;
            foreach(var pair in previousMasks)if(pair.Key!=null)pair.Key.cullingMask=pair.Value;
            QualitySettings.pixelLightCount=pixelLights;QualitySettings.shadowDistance=shadowDistance;
            QualitySettings.shadows=shadows;QualitySettings.shadowResolution=resolution;
            if(previous.IsValid()&&previous.isLoaded)SceneManager.SetActiveScene(previous);
            EditorSceneManager.CloseScene(scene,true);
            foreach(Object item in temporary)if(item!=null)Object.DestroyImmediate(item);
        }
    }

    public static string ArchiveReferences()
    {
        string destination=Repo+"/Tests/XStageTwoReferences.unitypackage";
        if(!AssetDatabase.IsValidFolder("Assets/TomXStageTwoAcceptance"))
            throw new Exception("Reference assets missing.");
        AssetDatabase.ExportPackage("Assets/TomXStageTwoAcceptance",destination,ExportPackageOptions.Recurse);
        AssetDatabase.Refresh();
        return "Exported reference scenes/materials/textures to "+destination+
            ". Shader dependency is provided by the same repository; native assets were exported by Unity.";
    }

    private static int FindUnusedLayer()
    {
        var used=new HashSet<int>();
        foreach(Renderer renderer in Object.FindObjectsOfType<Renderer>())used.Add(renderer.gameObject.layer);
        for(int i=31;i>=8;i--)if(!used.Contains(i))return i;
        throw new Exception("No unused layer for isolated regression.");
    }
    private static Light NewLight(LightType type,int layer,Vector3 position)
    {
        Light light=new GameObject("Regression "+type).AddComponent<Light>();
        light.type=type;light.cullingMask=1<<layer;light.transform.position=position;
        light.range=6;light.intensity=1;light.renderMode=LightRenderMode.ForcePixel;
        light.shadows=LightShadows.Soft;light.shadowBias=.02f;light.shadowNormalBias=.05f;
        return light;
    }
    private static Texture2D Solid(Color color)
    {
        var texture=new Texture2D(2,2,TextureFormat.RGBAFloat,false,true);
        texture.SetPixels(new[]{color,color,color,color});texture.Apply(false);return texture;
    }
}

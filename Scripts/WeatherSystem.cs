using System;
using System.Collections.Generic;
using UnityEngine;


public class WeatherSystem : MonoBehaviour
{
    //----------static---------------------------------------------------------
    static List<Action<WeatherSystem, bool>> s_listener = new List<Action<WeatherSystem, bool>>();

    public static void AddListener(System.Action<WeatherSystem, bool> listener)
    {
        s_listener.Remove(listener);
        s_listener.Add(listener);
    }

    public static void RemoveListener(System.Action<WeatherSystem, bool> listener)
    {
        s_listener.Remove(listener);
    }
    //-------------------------------------------------------------------------
    public enum WeatherType
    {
        Sunshine = 0,
        Rain,
        Snow,
    }

    //light
    public Light mainLight;
    public Renderer terrainRender;

    //sunshine 
    public float SunShineLightIntensity = 1.0f;
    public Color SunShineLightColor = Color.white;
    public float SunGloss = 2.0f;
    public float SunSpecular = 20.0f;

    //rain
    public float RainLightIntensity = 0.2f;
    public Color RainLightColor = Color.blue;
    public float RainGloss = 5.0f;
    public float RainSpecular = 60.0f;
    public Texture2D RainTex;
    public float RainSpecStrength = 2.6f;
    //todo rain particle

    //snow
    public float SnowLightIntensity = 0.8f;
    public Color SnowLightColor = Color.gray;
    public float SnowGloss = 5.0f;
    public float SnowSpecular = 60.0f;
    public Texture2D SnowTex;
    public float SnowLevel = 0.54f;
    public Vector2 SnowTerrainMinMax = new Vector2(0.5f,0.54f);
    //todo snow particle

    //scene obj
    public List<Renderer> sceneObj = new List<Renderer>();

    private WeatherType currentWeather = WeatherType.Sunshine;
    private WeatherType targetWeather = WeatherType.Sunshine;
    private float fadeTime = 2.0f;
    private float fadeTimeCounter = 0.0f;

    public void FadeWeatherTo(WeatherType target,float fadeTime)
    {
        if(fadeTimeCounter > 0)
        {
            UpdateParam(currentWeather, targetWeather, 1.0f);
            currentWeather = targetWeather;
            fadeTimeCounter = -0.1f;
        }

        if(fadeTime > 0.0f)
        {
            this.fadeTime = fadeTime;
            fadeTimeCounter = fadeTime;
            targetWeather = target;
        }
        else
        {
            UpdateParam(currentWeather, targetWeather, 1.0f);
            currentWeather = targetWeather;
        }
    }


    void Awake()
    {
        if(s_listener != null)
        {
            for(int i=0;i < s_listener.Count;++i)
            {
                s_listener[i](this, true);
            }
        }
    }

    void OnDestroy()
    {
        if (s_listener != null)
        {
            for (int i = 0; i < s_listener.Count; ++i)
            {
                s_listener[i](this, false);
            }
        }
    }

    //just for test
    void OnGUI()
    {
        if (GUI.Button(new Rect(10, 10, 100, 50), "sunshine"))
        {
            FadeWeatherTo(WeatherType.Sunshine, 3.0f);
        }

        if (GUI.Button(new Rect(10, 70, 100, 50), "rain"))
        {
            FadeWeatherTo(WeatherType.Rain, 3.0f);
        }

        if (GUI.Button(new Rect(10, 150, 100, 50), "snow"))
        {
            FadeWeatherTo(WeatherType.Snow, 3.0f);
        }
    }

    void Update()
    {
        if(fadeTimeCounter > 0.0f)
        {
            fadeTimeCounter -= Time.deltaTime;
            float f = 1.0f-Mathf.Clamp01(fadeTimeCounter/ fadeTime);

            UpdateParam(currentWeather, targetWeather, f);

            if(fadeTimeCounter <= 0.0f)
            {
                currentWeather = targetWeather;
            }
        }
    }

    void UpdateParam(WeatherType src, WeatherType des,float f)
    {
        float srcLightIntensity = 0.0f;
        Color srcLightColor = Color.black;
        float srcGloss = 1.0f;
        float srcSpecular = 1.0f;

        switch(src)
        {
            case WeatherType.Sunshine:
                {
                    srcLightIntensity = SunShineLightIntensity;
                    srcLightColor = SunShineLightColor;
                    srcGloss = SunGloss;
                    srcSpecular = SunSpecular;
                }
                break;

            case WeatherType.Rain:
                {
                    srcLightIntensity = RainLightIntensity;
                    srcLightColor = RainLightColor;
                    srcGloss = RainGloss;
                    srcSpecular = RainSpecular;
                }
                break;

            case WeatherType.Snow:
                {
                    srcLightIntensity = SnowLightIntensity;
                    srcLightColor = SnowLightColor;
                    srcGloss = SnowGloss;
                    srcSpecular = SnowSpecular;
                }
                break;
        }

        float desLightIntensity = 0.0f;
        Color desLightColor = Color.black;
        float desGloss = 1.0f;
        float desSpecular = 1.0f;
        Texture weatherTex = null;

        switch (des)
        {
            case WeatherType.Sunshine:
                {
                    desLightIntensity = SunShineLightIntensity;
                    desLightColor = SunShineLightColor;
                    desGloss = SunGloss;
                    desSpecular = SunSpecular;
                }
                break;

            case WeatherType.Rain:
                {
                    desLightIntensity = RainLightIntensity;
                    desLightColor = RainLightColor;
                    desGloss = RainGloss;
                    desSpecular = RainSpecular;
                    weatherTex = RainTex;
                }
                break;

            case WeatherType.Snow:
                {
                    desLightIntensity = SnowLightIntensity;
                    desLightColor = SnowLightColor;
                    desGloss = SnowGloss;
                    desSpecular = SnowSpecular;
                    weatherTex = SnowTex;
                }
                break;
        }

        //前半段变色
        float frontHalf = Mathf.Clamp01(f * 2);
        float backHalf = Mathf.Clamp01(f - 0.5f)*2;

        //Debug.Log(frontHalf.ToString() + "|" + backHalf.ToString());

        if (mainLight != null)
        {
            float intensity = Mathf.Lerp(srcLightIntensity, desLightIntensity, frontHalf);
            mainLight.intensity = intensity;
            mainLight.color = Color.Lerp(srcLightColor, desLightColor, frontHalf);
        }

        float snowLevel = 0.0f;
        if (terrainRender != null)
        {
            Material mat = terrainRender.sharedMaterial;

            float gloss = Mathf.Lerp(srcGloss, desGloss, frontHalf);
            mat.SetFloat("_Gloss", gloss);

            float specular = Mathf.Lerp(srcSpecular, desSpecular, frontHalf);
            mat.SetFloat("_Specular", specular);
            mat.SetColor("_SpecColor", mainLight.color);

            //要区分是从哪里切到哪里,来决定shader类型切换
            //src
            if (src == WeatherType.Rain)
            {
                if (backHalf > 0.95f)
                {
                    mat.SetFloat("_Weather", (int)des);
                }

                float specStrength = Mathf.Lerp(RainSpecStrength,0, frontHalf);
                mat.SetFloat("_RainGloss", specStrength);

                //雨天做特殊处理
                if (mainLight != null)
                {
                    float intensity = Mathf.Lerp(srcLightIntensity, desLightIntensity, backHalf);
                    mainLight.intensity = intensity;
                    mainLight.color = Color.Lerp(srcLightColor, desLightColor, backHalf);
                }
            }
            if (src == WeatherType.Snow)
            {
                if (backHalf > 0.95f)
                {
                    mat.SetFloat("_Weather", (int)des);
                }
                snowLevel = Mathf.Lerp(SnowLevel, 0, backHalf);
                float terrainSnowLevel = Mathf.Lerp(SnowTerrainMinMax.y, SnowTerrainMinMax.x, backHalf);
                mat.SetFloat("_Snow", terrainSnowLevel);
            }

            //des
            if (des == WeatherType.Rain)
            {
                if (backHalf > 0.0f && backHalf < 0.1f)
                {
                    mat.SetFloat("_Weather", (int)des);
                    mat.SetTexture("_WeatherTex", weatherTex);
                }
                float specStrength = Mathf.Lerp(0, RainSpecStrength, backHalf);
                mat.SetFloat("_RainGloss", specStrength);
            }
            if(des == WeatherType.Snow)
            {
                if (backHalf > 0.0f && backHalf < 0.1f)
                {
                    mat.SetFloat("_Weather", (int)des);
                    mat.SetTexture("_WeatherTex", weatherTex);
                }
                snowLevel = Mathf.Lerp(0, SnowLevel, backHalf);
                float terrainSnowLevel = Mathf.Lerp(SnowTerrainMinMax.x, SnowTerrainMinMax.y, backHalf);
                mat.SetFloat("_Snow", terrainSnowLevel);
               
            }
        }

        for(int i = 0;i < sceneObj.Count;++i)
        {
            Renderer render = sceneObj[i];
            if (render != null)
            {
                render.sharedMaterial.color = mainLight.color;
                if (src == WeatherType.Snow || des == WeatherType.Snow)
                {
                    render.sharedMaterial.SetFloat("_Snow", snowLevel);
                }
            }
        }
    }
    
}

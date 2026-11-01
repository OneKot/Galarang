using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Galarang.EditorTools
{
    /// <summary>
    /// Одноразовая настройка проекта: URP в Graphics/Quality, Linear color space,
    /// имя продукта. Запускается автоматически после импорта и из меню Galarang.
    /// </summary>
    [InitializeOnLoad]
    public static class GalarangProjectSetup
    {
        const string SettingsFolder = "Assets/_Galarang/Settings";
        const string UrpAssetPath = SettingsFolder + "/GalarangURP.asset";
        const string RendererAssetPath = SettingsFolder + "/GalarangRenderer.asset";

        static GalarangProjectSetup()
        {
            EditorApplication.delayCall += () => Setup(false);
        }

        [MenuItem("Galarang/Настроить проект")]
        public static void SetupFromMenu() => Setup(true);

        static void Setup(bool force)
        {
            // Только интерактивно: в batchmode смена PlayerSettings/GraphicsSettings
            // вызывает перезагрузку домена и срывает командный прогон тестов.
            if (Application.isBatchMode || EditorApplication.isPlayingOrWillChangePlaymode)
                return;

            EnsureFolder("Assets/_Galarang", "Settings");

            if (PlayerSettings.colorSpace != ColorSpace.Linear)
            {
                PlayerSettings.colorSpace = ColorSpace.Linear;
                Debug.Log("[Galarang] Color space: Linear.");
            }

            if (PlayerSettings.productName != "Galarang")
            {
                PlayerSettings.productName = "Galarang";
                PlayerSettings.companyName = "Galarang";
            }

            var urp = GraphicsSettings.defaultRenderPipeline as UniversalRenderPipelineAsset;
            if (urp == null || force)
            {
                var rendererData = AssetDatabase.LoadAssetAtPath<UniversalRendererData>(RendererAssetPath);
                if (rendererData == null)
                {
                    rendererData = ScriptableObject.CreateInstance<UniversalRendererData>();
                    AssetDatabase.CreateAsset(rendererData, RendererAssetPath);
                }

                urp = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(UrpAssetPath);
                if (urp == null)
                {
                    urp = ScriptableObject.CreateInstance<UniversalRenderPipelineAsset>();
                    var serialized = new SerializedObject(urp);
                    var rendererList = serialized.FindProperty("m_RendererDataList");
                    if (rendererList != null && rendererList.arraySize > 0)
                    {
                        rendererList.GetArrayElementAtIndex(0).objectReferenceValue = rendererData;
                        serialized.ApplyModifiedPropertiesWithoutUndo();
                    }
                    AssetDatabase.CreateAsset(urp, UrpAssetPath);
                }

                GraphicsSettings.defaultRenderPipeline = urp;
                AssetDatabase.SaveAssets();
                Debug.Log("[Galarang] URP назначен в Graphics.");
            }

            if (QualitySettings.renderPipeline != GraphicsSettings.defaultRenderPipeline)
            {
                QualitySettings.renderPipeline = GraphicsSettings.defaultRenderPipeline;
                Debug.Log("[Galarang] URP назначен в Quality.");
            }
        }

        static void EnsureFolder(string parent, string name)
        {
            if (!AssetDatabase.IsValidFolder($"{parent}/{name}"))
                AssetDatabase.CreateFolder(parent, name);
        }
    }
}

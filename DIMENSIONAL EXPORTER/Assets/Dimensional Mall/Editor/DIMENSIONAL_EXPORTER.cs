using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
using System.Linq;
using System.Collections.Generic;
using System;

namespace DimensionalMall {

    public class DIMENSIONAL_EXPORTER : EditorWindow {
        
        enum ShopType {
            Default,
            VIP
        }
        // List<string> shopTypeOptions = new List<string>{"Default", "VIP"};
        string[] shopTypeOptions = new string[]{"Default", "VIP"};

        const string TempFolder = "_DIMENSIONAL_EXPORTER_TEMP";
        const string OutputPath = "DIMENSIONAL_EXPORT.unitypackage";
        const string ExportFooter = "version 1.0.0 - dawnofender & saii";
        
        // for editor saving / loading
        const string PrefAuthor   = "DimensionalExporter.Author";
        const string PrefShop     = "DimensionalExporter.Shop";
        const string PrefEntrance = "DimensionalExporter.Entrance";
        const string PrefShopType = "DimensionalExporter.ShopType";
        
        const string PrefVersion  = "DimensionalExporter.Version";
        int shopVersion = 0; 

        string author = "";
        GameObject shopRoot;
        GameObject entranceRoot;
        ShopType shopType;
    
        ReviewStats shopLimits;
        ReviewStats entranceLimits;
        ReviewStats vipEntranceLimits;

        Reviewer shopReviewer;
        Reviewer entranceReviewer;

        VisualElement reviewField;
    
        [MenuItem("DIMENSIONAL EXPORTER/Menu")]
        public static void ShowWindow() {
            DIMENSIONAL_EXPORTER wnd = GetWindow<DIMENSIONAL_EXPORTER>();
            wnd.titleContent = new GUIContent("DIMENSIONAL EXPORTER");
        }
    
        void Init() {
    
            shopLimits = new ReviewStats {
                triangles = 100000,
                materialSlots = 15,
                bounds = new Vector3(30, 30, 30)
            };
            
            entranceLimits = new ReviewStats {
                triangles = 10000,
                materialSlots = 3,
                bounds = new Vector3(4f, 2.4f, .6f)
            };
    
            vipEntranceLimits = new ReviewStats {
                triangles = 10000,
                materialSlots = 3,
                bounds = new Vector3(10f, 2.4f, 1.2f)
            };

            shopReviewer = new Reviewer(shopLimits);
            entranceReviewer = new Reviewer(entranceLimits);
        }
    
        public void CreateGUI() {
            Init();
            author = EditorPrefs.GetString(PrefAuthor);
            shopRoot = LoadRef(PrefShop);
            entranceRoot = LoadRef(PrefEntrance);
            shopType = (ShopType)EditorPrefs.GetInt(PrefShopType);
            shopVersion = EditorPrefs.GetInt(PrefVersion);

            shopReviewer.Target = shopRoot;
            entranceReviewer.Target = entranceRoot;
            SetShopType(shopType);

            VisualElement root = rootVisualElement;
            
            Label label = new Label("DIMENSIONAL EXPORTER");
            label.style.fontSize = 21;
            label.style.unityFontStyleAndWeight = FontStyle.Bold;
            label.style.unityTextAlign = TextAnchor.MiddleCenter;
            root.Add(label);
    
            // Create shop name field
            var authorField = new TextField("Author");
            authorField.value = author;
            authorField.RegisterValueChangedCallback(evt => OnAuthorFieldChanged(evt.newValue));
            root.Add(authorField);

            // Create shop object field
            var shopObjectField = new ObjectField("Shop Object");
            shopObjectField.objectType = typeof(GameObject);
            shopObjectField.value = shopRoot;
            shopObjectField.RegisterValueChangedCallback(evt => OnShopObjectFieldChanged((GameObject)evt.newValue));
            root.Add(shopObjectField);
    
            // Create entrance object field
            var entranceObjectField = new ObjectField("Entrance Object");
            entranceObjectField.objectType = typeof(GameObject);
            entranceObjectField.value = entranceRoot;
            entranceObjectField.RegisterValueChangedCallback(evt => OnEntranceObjectFieldChanged((GameObject)evt.newValue));
            root.Add(entranceObjectField);
            
            // Create shop type dropdown field
            var shopTypeDropdown = new DropdownField("Shop Type", shopTypeOptions.ToList(), (int)shopType);
            shopTypeDropdown.RegisterValueChangedCallback(evt => OnShopTypeDropdownFieldChanged(evt.newValue));
            root.Add(shopTypeDropdown);

            // Entrance size label
            // (Entrance size: x:11 y:6 z:3)
            // (Entrance size: x:25 y:6 z:3)

            // Create review fields
            reviewField = new VisualElement();
            root.Add(reviewField);
            
            // Review and Export buttons
            var reviewButton = new Button(UpdateReviews);
            reviewButton.text = "Refresh review";
            root.Add(reviewButton);
            
            var exportButton = new Button(Export);
            exportButton.text = "Export";
            root.Add(exportButton);

            // footer
            Label footer = new Label(ExportFooter);
            footer.style.fontSize = 10;
            footer.style.unityTextAlign = TextAnchor.MiddleCenter;
            root.Add(footer);

            UpdateReviews();
        }

        void OnDisable() {
            SaveChanges();
        }

        void OnAuthorFieldChanged(string newValue) {
            author = newValue;
            SaveChanges();
        }
    
        void OnShopObjectFieldChanged(GameObject newValue) {
            shopRoot = newValue;
            SaveChanges();
            shopReviewer.Target = newValue;
            shopReviewer.UpdateReview();
            UpdateReviewField();
        }
        
        void OnEntranceObjectFieldChanged(GameObject newValue) {
            entranceRoot = newValue;
            SaveChanges();
            entranceReviewer.Target = newValue;
            entranceReviewer.UpdateReview();
            UpdateReviewField();
        }

        void OnShopTypeDropdownFieldChanged(string newValue) {
            SetShopType((ShopType)Array.IndexOf(shopTypeOptions, newValue));
            SaveChanges();
            entranceReviewer.UpdateReview();
            UpdateReviewField();
        }

        new void SaveChanges() {
            EditorPrefs.SetString(PrefAuthor, author);
            SaveRef(PrefShop, shopRoot);
            SaveRef(PrefEntrance, entranceRoot);
            EditorPrefs.SetInt(PrefShopType, (int)shopType);
            base.SaveChanges();
        }

        void SetShopType(ShopType newShopType) {
            shopType = newShopType;
            switch(shopType) {
                case ShopType.Default: entranceReviewer.Limits = entranceLimits;    break;
                case ShopType.VIP:     entranceReviewer.Limits = vipEntranceLimits; break;
                default: break;
            }
        }

        void UpdateReviews() {
            shopReviewer.UpdateReview();
            entranceReviewer.UpdateReview();
            UpdateReviewField();
        }

        void UpdateReviewField() {
            reviewField.Clear();
            reviewField.Add(BuildReviewField(shopReviewer, "\nShop Review"));
            reviewField.Add(BuildReviewField(entranceReviewer, "\nEntrance Review"));
            reviewField.Add(ReviewEntry(""));
        }
        
        void UpdateShopReview() {
            shopReviewer.UpdateReview();
            UpdateReviewField();
        }

        void UpdateEntranceReview() {
            entranceReviewer.UpdateReview();
            UpdateReviewField();
        }
    
        void Export() {
            UpdateReviews();

            if (author == "") {
                Debug.LogError("Can't export, author not set.");
                return;
            }

            if (!shopReviewer.Passed) {
                Debug.LogError("Can't export, shop did not pass review.");
                return;
            }

            if (!entranceReviewer.Passed) {
                Debug.LogError("Can't export, entrance did not pass review.");
                return;
            }
    
            try {
                string folder = $"{author} v{shopVersion}";
                if (AssetDatabase.IsValidFolder("Assets/" + TempFolder))
                    AssetDatabase.DeleteAsset("Assets/" + TempFolder);
                AssetDatabase.CreateFolder("Assets", TempFolder);
                AssetDatabase.CreateFolder($"Assets/{TempFolder}", folder);
                
                string shopPrefab     = GetPrefabPath(shopRoot,     $"{folder}/shop");
                string entrancePrefab = GetPrefabPath(entranceRoot, $"{folder}/entrance");
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
                foreach (var dep in AssetDatabase.GetDependencies(new[] { shopPrefab, entrancePrefab }, true))
                    Debug.Log(dep);
                AssetDatabase.ExportPackage(new[] { shopPrefab, entrancePrefab }, OutputPath, ExportPackageOptions.IncludeDependencies);
    
                Debug.Log($"Exported shop to {OutputPath}");
                EditorUtility.RevealInFinder(OutputPath);
                
                shopVersion++;
                EditorPrefs.SetInt(PrefVersion, shopVersion);
            }
            finally {
                AssetDatabase.DeleteAsset("Assets/" + TempFolder);
                AssetDatabase.Refresh();
            }
        }
    
        VisualElement BuildReviewField(Reviewer reviewer, string header) {
            var field = new VisualElement();

            field.Add(ReviewMessage(header, Color.white));

            if (reviewer.Target == null) {
                field.Add(ReviewEntry($"Object not selected"));
                return field;
            }

            field.Add(ReviewEntry($"triangle count: {reviewer.TargetStats.triangles} / {reviewer.Limits.triangles}"));
            field.Add(ReviewEntry($"material count: {reviewer.TargetStats.materialSlots} / {reviewer.Limits.materialSlots}"));
            field.Add(ReviewEntry($"bounds: {reviewer.TargetStats.bounds} / {reviewer.Limits.bounds}"));

            field.Add(reviewer.Passed
                ? ReviewMessage("passed review, yippee!", Color.green)
                : ReviewMessage($"did not pass review D:{((reviewer.Message != "")? $"\nreason: {reviewer.Message}" : "")}", Color.red));
            
            return field;
        }
    
        Label ReviewMessage(string message, Color color) {
            var label = new Label(message);
            label.style.fontSize = 16;
            label.style.unityTextAlign = TextAnchor.MiddleCenter;
            label.style.unityFontStyleAndWeight = FontStyle.Bold;
            label.style.color = color;
            return label;
        }
    
        Label ReviewEntry(string message) {
            var label = new Label(message);
            label.style.fontSize = 16;
            label.style.unityTextAlign = TextAnchor.MiddleCenter;
            return label;
        }
        
        static string GetPrefabPath(GameObject root, string name) {
            string path = $"Assets/{TempFolder}/{name}.prefab";

            // Make a throwaway copy so the original asset/scene object is never touched
            GameObject copy = EditorUtility.IsPersistent(root)
                ? (GameObject)PrefabUtility.InstantiatePrefab(root)
                : UnityEngine.Object.Instantiate(root);
            copy.name = root.name; // strip "(Clone)"

            try {
                if (PrefabUtility.IsPartOfPrefabInstance(copy)) {
                    PrefabUtility.UnpackPrefabInstance(
                        copy,
                        PrefabUnpackMode.Completely,
                        InteractionMode.AutomatedAction);
                }
                PrefabUtility.SaveAsPrefabAsset(copy, path);
            }
            finally {
                UnityEngine.Object.DestroyImmediate(copy);
            }
            return path;
        }

        static void SaveRef(string key, GameObject go) =>
            EditorPrefs.SetString(key, go == null ? "" : GlobalObjectId.GetGlobalObjectIdSlow(go).ToString());
        
        static GameObject LoadRef(string key) {
            string s = EditorPrefs.GetString(key, "");
            if (!GlobalObjectId.TryParse(s, out var id)) return null;
            return GlobalObjectId.GlobalObjectIdentifierToObjectSlow(id) as GameObject;
        }
    }
    
    public struct ReviewStats {
        public int triangles;
        public int materialSlots;
        public Vector3 bounds;
    }
    
    public class Reviewer {
        GameObject _target;
        ReviewStats _limits;
        ReviewStats _targetStats;
        bool _passed;
        string _message = "";

        public GameObject Target {
            get => _target;
            set => _target = value;
        }

        public ReviewStats Limits {
            get => _limits;
            set => _limits = value;
        }

        public ReviewStats TargetStats {
            get => _targetStats;
        }
        
        public bool Passed {
            get => _passed;
        }
        
        public string Message {
            get => _message;
        }
        
        public Reviewer(ReviewStats limits) {
            _limits = limits;
        }

        public Reviewer(GameObject target, ReviewStats limits) {
            _target = target;
            _limits = limits;
        }
    
        public void UpdateReview() {
            _message = "";
            _targetStats = CheckObject(_target);
            _passed = false;
            
            if (_target == null) {
                _message = "No object selected";
                return;
            }
            
            // NOTE: honestly not sure if this is necessary but it seems to work fine without it
            // if (!CheckUniqueNames(_target)) {
            //     _message = "All objects must have different names";
            //     return;
            // }


            _passed = (CheckReview(_limits, _targetStats) >= 0);

        }
        
        // -1 if any limits < targetStats
        // 0 if all limits == targetStats
        // 1 if all limits > targetStats
        static int CheckReview(ReviewStats limits, ReviewStats targetStats) {
            int[] comparisons = {
                limits.triangles.CompareTo(targetStats.triangles),
                limits.materialSlots.CompareTo(targetStats.materialSlots),
                limits.bounds.x.CompareTo(targetStats.bounds.x),
                limits.bounds.y.CompareTo(targetStats.bounds.y),
                limits.bounds.z.CompareTo(targetStats.bounds.z)
            };

            return comparisons.Min();
        }
    
        static ReviewStats CheckObject(GameObject target) {
            if (target == null) return new ReviewStats{
                triangles = 0,
                materialSlots = 0,
                bounds = Vector3.zero
            };

            var renderers = target.GetComponentsInChildren<Renderer>();
            return new ReviewStats {
                triangles = CountTriangles(target),
                materialSlots = CountMaterialSlots(renderers),
                bounds = CheckBounds(renderers)
            };
        }
    
        static int CountTriangles(GameObject target) {
            if (target == null) return 0;
            int count = 0;
            foreach (var meshFilter in target.GetComponentsInChildren<MeshFilter>()) {
                if (meshFilter.sharedMesh == null) continue;
                count += meshFilter.sharedMesh.triangles.Length / 3;
            }
            return count;
        }
        
        static int CountMaterialSlots(Renderer[] renderers) {
            var count = new HashSet<Material>();
            foreach (var renderer in renderers)
                count.Add(renderer.sharedMaterial);
            return count.Count;
        }
    
        static Vector3 CheckBounds(Renderer[] renderers) {
            if (renderers.Length == 0) return Vector3.zero;
            var bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
                bounds.Encapsulate(renderers[i].bounds);
            return bounds.size;
        }
        
        static bool CheckUniqueNames(GameObject target) {
            return CheckUniqueNames(target, new HashSet<string>());
        }

        static bool CheckUniqueNames(GameObject target, HashSet<string> names) {
            if (names.Contains(target.name)) return false;
            names.Add(target.name);
            foreach (Transform child in target.transform) {
                if (!CheckUniqueNames(child.gameObject, names)) return false;
            }
            return true;
        }
        
    
        static int CountMaterialSlots(GameObject target) {
            if (target == null) return 0;
            return CountMaterialSlots(target.GetComponentsInChildren<Renderer>());
        }
    
        static Vector3 CheckBounds(GameObject target) {
            if (target == null) return Vector3.zero;
            return CheckBounds(target.GetComponentsInChildren<Renderer>());
        }
    }
}


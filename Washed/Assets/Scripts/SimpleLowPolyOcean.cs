using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class SimpleLowPolyOcean : MonoBehaviour
{
    [Header("Ocean Size")]
    [Min(1)] public int gridSize = 100;
    [Min(0.1f)] public float cellSize = 5f;

    [Header("Visible Waves")]
    [Range(0f, 5f)] public float waveHeight = 1.2f;
    [Min(1f)] public float waveLength = 14f;
    [Range(0f, 3f)] public float waveSpeed = 0.65f;
    [Range(0f, 1f)] public float choppiness = 0.4f;

    private Mesh mesh;
    private Vector3[] vertices;
    private int[] triangles;
    private int previousGridSize;
    private float previousCellSize;
    private float timeOffset;

    private void OnEnable() { BuildMesh(); }
    private void OnValidate() { gridSize = Mathf.Clamp(gridSize, 1, 160); cellSize = Mathf.Max(0.1f, cellSize); waveLength = Mathf.Max(1f, waveLength); }
    private void Update()
    {
        if (mesh == null || gridSize != previousGridSize || !Mathf.Approximately(cellSize, previousCellSize)) BuildMesh();
        if (mesh == null) return;
        if (Application.isPlaying) timeOffset += Time.deltaTime * waveSpeed;
        UpdateWaves(timeOffset);
    }

    private void BuildMesh()
    {
        if (mesh != null) { if (Application.isPlaying) Destroy(mesh); else DestroyImmediate(mesh); }
        mesh = new Mesh { name = "Generated Faceted Ocean" };
        mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        int count = gridSize * gridSize;
        vertices = new Vector3[count * 6];
        triangles = new int[vertices.Length];
        for (int i = 0; i < triangles.Length; i++) triangles[i] = i;
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        GetComponent<MeshFilter>().sharedMesh = mesh;
        previousGridSize = gridSize;
        previousCellSize = cellSize;
        UpdateWaves(timeOffset);
    }

    private float Height(float x, float z, float t)
    {
        float k = 2f * Mathf.PI / waveLength;
        float a = Mathf.Sin((x * 0.87f + z * 0.49f) * k + t * 1.2f);
        float b = Mathf.Sin((x * -0.32f + z * 0.95f) * k * 1.37f + t * 0.83f);
        float c = Mathf.Sin((x * 0.66f - z * 0.75f) * k * 2.15f - t * 1.5f);
        return waveHeight * (0.62f * a + 0.28f * b + choppiness * 0.22f * c);
    }

    // Matches the actual triangular mesh surface (not just the smooth wave formula).
    public float GetWaterHeight(Vector3 worldPosition)
    {
        Vector3 local = transform.InverseTransformPoint(worldPosition);
        float half = gridSize * cellSize * 0.5f;
        float gx = Mathf.Clamp((local.x + half) / cellSize, 0f, gridSize - 0.0001f);
        float gz = Mathf.Clamp((local.z + half) / cellSize, 0f, gridSize - 0.0001f);
        int ix = Mathf.FloorToInt(gx), iz = Mathf.FloorToInt(gz);
        float u = gx - ix, v = gz - iz;
        float x0 = ix * cellSize - half, z0 = iz * cellSize - half;
        float a = Height(x0, z0, timeOffset);
        float b = Height(x0, z0 + cellSize, timeOffset);
        float c = Height(x0 + cellSize, z0, timeOffset);
        float d = Height(x0 + cellSize, z0 + cellSize, timeOffset);
        float y = u + v <= 1f
            ? a * (1f - u - v) + b * v + c * u
            : d * (u + v - 1f) + b * (1f - u) + c * (1f - v);
        return transform.TransformPoint(new Vector3(local.x, y, local.z)).y;
    }

    private void UpdateWaves(float t)
    {
        if (vertices == null || mesh == null) return;
        float half = gridSize * cellSize * 0.5f;
        int index = 0;
        for (int z = 0; z < gridSize; z++)
        for (int x = 0; x < gridSize; x++)
        {
            float x0 = x * cellSize - half, x1 = x0 + cellSize;
            float z0 = z * cellSize - half, z1 = z0 + cellSize;
            Vector3 a = new Vector3(x0, Height(x0,z0,t), z0);
            Vector3 b = new Vector3(x0, Height(x0,z1,t), z1);
            Vector3 c = new Vector3(x1, Height(x1,z0,t), z0);
            Vector3 d = new Vector3(x1, Height(x1,z1,t), z1);
            vertices[index++] = a; vertices[index++] = b; vertices[index++] = c;
            vertices[index++] = c; vertices[index++] = b; vertices[index++] = d;
        }
        mesh.vertices = vertices;
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();
    }

    private void OnDisable()
    {
        if (mesh == null) return;
        if (GetComponent<MeshFilter>() != null && GetComponent<MeshFilter>().sharedMesh == mesh) GetComponent<MeshFilter>().sharedMesh = null;
        if (Application.isPlaying) Destroy(mesh); else DestroyImmediate(mesh);
        mesh = null;
    }
}

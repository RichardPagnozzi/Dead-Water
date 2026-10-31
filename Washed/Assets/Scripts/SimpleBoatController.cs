using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

// Arcade movement + upright buoyancy. Attach only to the boat root.
public class SimpleBoatController : MonoBehaviour
{
    public SimpleLowPolyOcean ocean;
    [Header("Movement")]
    public float forwardSpeed = 7f;
    public float reverseSpeed = 3f;
    public float turnSpeed = 75f;
    [Header("Floating")]
    public float boatLength = 6f;
    public float boatWidth = 3f;
    public float waterlineOffset = 0f;
    public float positionSmooth = 6f;
    public float rotationSmooth = 4f;
    [Range(0f, 25f)] public float maxTiltDegrees = 12f;

    float yaw;
    float smoothPitch;
    float smoothRoll;

    void Start()
    {
        yaw = transform.eulerAngles.y;
        if (!ocean) ocean = FindFirstObjectByType<SimpleLowPolyOcean>();
    }

    void Update()
    {
        float throttle = 0f;
        float steer = 0f;
#if ENABLE_INPUT_SYSTEM
        if (Keyboard.current != null)
        {
            if (Keyboard.current.wKey.isPressed || Keyboard.current.upArrowKey.isPressed) throttle += 1f;
            if (Keyboard.current.sKey.isPressed || Keyboard.current.downArrowKey.isPressed) throttle -= 1f;
            if (Keyboard.current.dKey.isPressed || Keyboard.current.rightArrowKey.isPressed) steer += 1f;
            if (Keyboard.current.aKey.isPressed || Keyboard.current.leftArrowKey.isPressed) steer -= 1f;
        }
#elif ENABLE_LEGACY_INPUT_MANAGER
        throttle = Input.GetAxisRaw("Vertical");
        steer = Input.GetAxisRaw("Horizontal");
#endif
        // Immediate tank-style controls: turn in place, no inertia or reverse steering inversion.
        yaw += steer * turnSpeed * Time.deltaTime;
        float speed = throttle >= 0f ? throttle * forwardSpeed : throttle * reverseSpeed;
        Quaternion heading = Quaternion.Euler(0f, yaw, 0f);
        Vector3 forward = heading * Vector3.forward;
        Vector3 right = heading * Vector3.right;
        Vector3 p = transform.position + forward * (speed * Time.deltaTime);
        Quaternion desiredRotation = heading;

        if (ocean != null)
        {
            float halfLength = Mathf.Max(0.1f, boatLength) * 0.5f;
            float halfWidth = Mathf.Max(0.1f, boatWidth) * 0.5f;
            float center = ocean.GetWaterHeight(p);
            float bow = ocean.GetWaterHeight(p + forward * halfLength);
            float stern = ocean.GetWaterHeight(p - forward * halfLength);
            float rightHeight = ocean.GetWaterHeight(p + right * halfWidth);
            float leftHeight = ocean.GetWaterHeight(p - right * halfWidth);
            float targetY = (center + bow + stern + rightHeight + leftHeight) / 5f + waterlineOffset;
            p.y = Mathf.Lerp(transform.position.y, targetY, 1f - Mathf.Exp(-positionSmooth * Time.deltaTime));

            float pitch = Mathf.Atan2(bow - stern, halfLength * 2f) * Mathf.Rad2Deg;
            float roll = -Mathf.Atan2(rightHeight - leftHeight, halfWidth * 2f) * Mathf.Rad2Deg;
            pitch = Mathf.Clamp(pitch, -maxTiltDegrees, maxTiltDegrees);
            roll = Mathf.Clamp(roll, -maxTiltDegrees, maxTiltDegrees);
            float tiltBlend = 1f - Mathf.Exp(-Mathf.Max(0f, rotationSmooth) * Time.deltaTime);
            smoothPitch = Mathf.Lerp(smoothPitch, -pitch, tiltBlend);
            smoothRoll = Mathf.Lerp(smoothRoll, roll, tiltBlend);
            desiredRotation = heading * Quaternion.Euler(smoothPitch, 0f, smoothRoll);
        }
        transform.SetPositionAndRotation(p, desiredRotation);
    }
}

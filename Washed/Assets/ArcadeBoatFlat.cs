using UnityEngine;
using UnityEngine.InputSystem;

// Attach to the controller parent; model should face local +Z.
public class ArcadeBoatFlat : MonoBehaviour
{
    [Min(0)] public float forwardSpeed = 7f;
    [Min(0)] public float reverseSpeed = 4f;
    [Min(0)] public float turnSpeed = 140f;
    public float waterLevel = 0f;
    public float boatHeightAboveWater = 0.2f;

    void Update()
    {
        if (Keyboard.current == null) return;
        var k = Keyboard.current;
        float forward = (k.wKey.isPressed || k.upArrowKey.isPressed ? 1f : 0f)
                      - (k.sKey.isPressed || k.downArrowKey.isPressed ? 1f : 0f);
        float turn = (k.dKey.isPressed || k.rightArrowKey.isPressed ? 1f : 0f)
                   - (k.aKey.isPressed || k.leftArrowKey.isPressed ? 1f : 0f);
        transform.Rotate(0f, turn * turnSpeed * Time.deltaTime, 0f, Space.World);
        float speed = forward >= 0 ? forwardSpeed : reverseSpeed;
        transform.position += transform.forward * (forward * speed * Time.deltaTime);
        Vector3 p = transform.position;
        p.y = waterLevel + boatHeightAboveWater;
        transform.position = p;
    }
}

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using UnityEngine.Events;
using System.Collections;
using System.Collections.Generic;

namespace Framework
{
    public class UIModelController : Graphic, IDragHandler, IPointerDownHandler, IPointerUpHandler
    {
        public Transform _target;
        public float _speed = -1.0f;

        public float _clickDuration = 0.3f;
        public float _doubleClickDuration = 0.3f;
        public float _dragThreshold = 5;

        private float _lastUpTime = 0;
        private Vector2 _clickedPosition;

        public Button.ButtonClickedEvent onClick { get; set; }
        public Button.ButtonClickedEvent onDoubleClick { get; set; }

        protected override void OnDisable()
        {
            base.OnDisable();
        }

        protected override void OnEnable()
        {
            base.OnEnable();
            canvasRenderer.SetAlpha(0);
        }

        public UIModelController()
        {
            onClick = new Button.ButtonClickedEvent();
            onDoubleClick = new Button.ButtonClickedEvent();
        }

        public void SetTarget(Transform _trans)
        {
            _target = _trans;
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (_target != null)
            {
                _target.localRotation = Quaternion.Euler(0f, _speed * eventData.delta.x, 0f) * _target.localRotation;
            }
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            _clickedPosition = eventData.position;
        }

        private IEnumerator CoDelayClickEvent()
        {
            yield return new WaitForSeconds(_doubleClickDuration);
            if (onClick != null)
            {
                onClick.Invoke();
            }
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if ((eventData.position - _clickedPosition).sqrMagnitude < _dragThreshold * _dragThreshold)
            {
                if (eventData.clickTime - _lastUpTime < _doubleClickDuration)
                {
                    StopAllCoroutines();
                    if (onDoubleClick != null)
                    {
                        onDoubleClick.Invoke();
                    }
                }
                else
                {
                    StartCoroutine(CoDelayClickEvent());
                }
            }
            _lastUpTime = eventData.clickTime;
        }
    }
}
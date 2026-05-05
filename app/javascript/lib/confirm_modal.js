/**
 * Centered modal confirmation (replaces toast-style confirms for Turbo `data-turbo-confirm`).
 * Returns a Promise<boolean>. Focuses the safe action (Cancel) first for destructive flows.
 */

const MODAL_HTML_ID = () =>
  `app-confirm-modal-title-${Math.random().toString(36).slice(2, 9)}`;

export function showConfirmModal(message, options = {}) {
  const {
    title = '',
    confirmText = 'OK',
    cancelText = 'Cancel',
    variant = 'danger',
  } = options;

  return new Promise((resolve) => {
    const headingId = MODAL_HTML_ID();
    let settled = false;

    const wrap = document.createElement('div');
    wrap.className = 'app-confirm-modal';

    const backdrop = document.createElement('button');
    backdrop.type = 'button';
    backdrop.className = 'app-confirm-modal__backdrop';

    backdrop.setAttribute('aria-label', cancelText);

    const panel = document.createElement('div');
    panel.className = 'app-confirm-modal__panel';
    panel.setAttribute('role', 'dialog');
    panel.setAttribute('aria-modal', 'true');

    const labelFallback =
      String(message || '')
        .replace(/\s+/g, ' ')
        .trim()
        .slice(0, 80) || 'Confirm';

    if (title) {
      panel.setAttribute('aria-labelledby', headingId);
    } else {
      panel.setAttribute('aria-label', labelFallback);
    }

    if (title) {
      const h = document.createElement('h2');
      h.className = 'app-confirm-modal__title';
      h.id = headingId;
      h.textContent = title;
      panel.appendChild(h);
    }

    const msg = document.createElement('p');
    msg.className = 'app-confirm-modal__body';
    msg.textContent = String(message);

    panel.appendChild(msg);

    const actions = document.createElement('div');
    actions.className = 'app-confirm-modal__actions';

    const cancelBtn = document.createElement('button');
    cancelBtn.type = 'button';
    cancelBtn.className =
      'app-confirm-modal__btn app-confirm-modal__btn--cancel';
    cancelBtn.textContent = cancelText;

    const confirmBtn = document.createElement('button');
    confirmBtn.type = 'button';
    confirmBtn.className =
      variant === 'danger'
        ? 'app-confirm-modal__btn app-confirm-modal__btn--danger'
        : 'app-confirm-modal__btn app-confirm-modal__btn--confirm';
    confirmBtn.textContent = confirmText;

    actions.append(cancelBtn, confirmBtn);
    panel.append(actions);

    wrap.append(backdrop, panel);

    const finish = (result) => {
      if (settled) return;
      settled = true;
      document.body.style.overflow = '';
      document.removeEventListener('keydown', onKeyDown);
      wrap.remove();
      resolve(result);
    };

    const onKeyDown = (e) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        finish(false);
      }
    };

    backdrop.addEventListener('click', () => finish(false));
    cancelBtn.addEventListener('click', () => finish(false));
    confirmBtn.addEventListener('click', () => finish(true));

    document.addEventListener('keydown', onKeyDown);
    document.body.style.overflow = 'hidden';
    document.body.appendChild(wrap);

    window.requestAnimationFrame(() => {
      cancelBtn.focus();
    });
  });
}

(() => {
  const languages = [
    ['English', 'en'], ['简体中文', 'zh-CN'], ['繁體中文', 'zh-TW'], ['Español', 'es'],
    ['हिन्दी', 'hi'], ['Français', 'fr'], ['Português', 'pt'], ['Русский', 'ru'],
    ['日本語', 'ja'], ['한국어', 'ko']
  ];
  const translations = {
    'Download': ['Download', '下载', '下載', 'Descargar', 'डाउनलोड', 'Télécharger', 'Baixar', 'Скачать', 'ダウンロード', '다운로드'],
    'FAQ': ['FAQ', '常见问题', '常見問題', 'Preguntas frecuentes', 'अक्सर पूछे जाने वाले प्रश्न', 'FAQ', 'Perguntas frequentes', 'Часто задаваемые вопросы', 'よくある質問', '자주 묻는 질문'],
    'Privacy Policy': ['Privacy Policy', '隐私政策', '隱私權政策', 'Política de privacidad', 'गोपनीयता नीति', 'Politique de confidentialité', 'Política de privacidade', 'Политика конфиденциальности', 'プライバシーポリシー', '개인정보 처리방침'],
    'EULA': ['EULA', '最终用户许可协议', '最終使用者授權合約', 'Acuerdo de licencia de usuario final', 'अंतिम उपयोगकर्ता लाइसेंस समझौता', 'Contrat de licence utilisateur final', 'Contrato de licença de usuário final', 'Лицензионное соглашение', 'エンドユーザーライセンス契約', '최종 사용자 라이선스 계약'],
    'Support': ['Support', '支持', '支援', 'Soporte', 'सहायता', 'Assistance', 'Suporte', 'Поддержка', 'サポート', '지원'],
    'Release Notes': ['Release Notes', '发行说明', '版本說明', 'Notas de versión', 'रिलीज़ नोट्स', 'Notes de version', 'Notas de versão', 'Примечания к выпуску', 'リリースノート', '릴리스 노트'],
    'Face ID for Mac': ['Face ID for Mac', 'Mac 用 Face ID', 'Mac 用 Face ID', 'Face ID para Mac', 'Mac के लिए Face ID', 'Face ID pour Mac', 'Face ID para Mac', 'Face ID для Mac', 'Mac 用 Face ID', 'Mac용 Face ID'],
    'Your face.': ['Your face.', '你的脸。', '你的臉。', 'Tu rostro.', 'आपका चेहरा।', 'Votre visage.', 'Seu rosto.', 'Ваше лицо.', 'あなたの顔。', '당신의 얼굴.'],
    'Your': ['Your', '你的', '你的', 'Tu', 'आपका', 'Votre', 'Seu', 'Ваш', 'あなたの', '당신의'],
    'Mac.': ['Mac.', 'Mac。', 'Mac。', 'Mac.', 'Mac।', 'Mac.', 'Mac.', 'Mac.', 'Mac。', 'Mac.'],
    'A simple, private way to unlock your Mac using your face. Built to feel like it belongs on macOS.': ['A simple, private way to unlock your Mac using your face. Built to feel like it belongs on macOS.', '用你的面孔简单、私密地解锁 Mac。为 macOS 打造，使用起来浑然一体。', '用你的臉簡單、私密地解鎖 Mac。專為 macOS 打造，使用起來自然流暢。', 'Una forma sencilla y privada de desbloquear tu Mac con el rostro. Diseñado para sentirse parte de macOS.', 'चेहरे से Mac अनलॉक करने का आसान, निजी तरीका। macOS का स्वाभाविक हिस्सा जैसा अनुभव।', 'Un moyen simple et privé de déverrouiller votre Mac avec votre visage. Conçu pour s’intégrer à macOS.', 'Uma forma simples e privada de desbloquear o Mac usando seu rosto. Feito para parecer parte do macOS.', 'Простой и конфиденциальный способ разблокировать Mac с помощью лица. Создано для естественной работы в macOS.', '顔で Mac をシンプルかつプライベートにロック解除。macOS の一部のような使い心地です。', '얼굴로 Mac을 간단하고 안전하게 잠금 해제하세요. macOS에 자연스럽게 어울리도록 설계했습니다.'],
    'End User License Agreement': ['End User License Agreement', '最终用户许可协议', '最終使用者授權合約', 'Acuerdo de licencia de usuario final', 'अंतिम उपयोगकर्ता लाइसेंस समझौता', 'Contrat de licence utilisateur final', 'Contrato de licença de usuário final', 'Лицензионное соглашение конечного пользователя', 'エンドユーザーライセンス契約', '최종 사용자 라이선스 계약'],
    'Frequently Asked Questions': ['Frequently Asked Questions', '常见问题', '常見問題', 'Preguntas frecuentes', 'अक्सर पूछे जाने वाले प्रश्न', 'Questions fréquemment posées', 'Perguntas frequentes', 'Часто задаваемые вопросы', 'よくある質問', '자주 묻는 질문'],
    'Need help with FaceAuth?': ['Need help with FaceAuth?', '需要 FaceAuth 帮助吗？', '需要 FaceAuth 協助嗎？', '¿Necesitas ayuda con FaceAuth?', 'FaceAuth में सहायता चाहिए?', 'Besoin d’aide avec FaceAuth ?', 'Precisa de ajuda com o FaceAuth?', 'Нужна помощь с FaceAuth?', 'FaceAuth についてお困りですか？', 'FaceAuth에 도움이 필요하신가요?'],
    "We're here to help.": ['We’re here to help.', '我们很乐意帮助你。', '我們很樂意提供協助。', 'Estamos aquí para ayudarte.', 'हम आपकी सहायता के लिए यहाँ हैं।', 'Nous sommes là pour vous aider.', 'Estamos aqui para ajudar.', 'Мы готовы помочь.', 'お手伝いします。', '도와드리겠습니다.'],
    'General': ['General', '常规', '一般', 'General', 'सामान्य', 'Général', 'Geral', 'Общие сведения', '一般', '일반'],
    'Privacy & Offline': ['Privacy & Offline', '隐私与离线', '隱私與離線', 'Privacidad y uso sin conexión', 'गोपनीयता और ऑफ़लाइन', 'Confidentialité et mode hors ligne', 'Privacidade e offline', 'Конфиденциальность и офлайн-режим', 'プライバシーとオフライン', '개인정보 보호 및 오프라인'],
    'Security': ['Security', '安全性', '安全性', 'Seguridad', 'सुरक्षा', 'Sécurité', 'Segurança', 'Безопасность', 'セキュリティ', '보안'],
    'Camera': ['Camera', '摄像头', '相機', 'Cámara', 'कैमरा', 'Caméra', 'Câmera', 'Камера', 'カメラ', '카메라'],
    'Software Requirements': ['Software Requirements', '软件要求', '軟體需求', 'Requisitos de software', 'सॉफ़्टवेयर आवश्यकताएँ', 'Configuration requise', 'Requisitos de software', 'Системные требования', 'ソフトウェア要件', '소프트웨어 요구 사항'],
    'System requirements': ['System requirements', '系统要求', '系統需求', 'Requisitos del sistema', 'सिस्टम आवश्यकताएँ', 'Configuration système', 'Requisitos do sistema', 'Системные требования', 'システム要件', '시스템 요구 사항'],
    'Current status': ['Current status', '当前状态', '目前狀態', 'Estado actual', 'वर्तमान स्थिति', 'État actuel', 'Status atual', 'Текущий статус', '現在の状況', '현재 상태'],
    'Official Release': ['Official Release', '正式版', '正式版本', 'Lanzamiento oficial', 'आधिकारिक रिलीज़', 'Version officielle', 'Lançamento oficial', 'Официальный выпуск', '正式リリース', '정식 출시'],
    'Beta': ['Beta', '测试版', '測試版', 'Beta', 'बीटा', 'Bêta', 'Beta', 'Бета', 'ベータ版', '베타'],
    'Go Back': ['Go Back', '返回', '返回', 'Volver', 'वापस जाएँ', 'Retour', 'Voltar', 'Назад', '戻る', '뒤로'],
    'Download Beta': ['Download Beta', '下载测试版', '下載測試版', 'Descargar la beta', 'बीटा डाउनलोड करें', 'Télécharger la bêta', 'Baixar a versão beta', 'Скачать бета-версию', 'ベータ版をダウンロード', '베타 다운로드'],
    'The beta isn’t available yet.': ['The beta isn’t available yet.', '测试版尚未推出。', '測試版尚未推出。', 'La beta aún no está disponible.', 'बीटा अभी उपलब्ध नहीं है।', 'La bêta n’est pas encore disponible.', 'A versão beta ainda não está disponível.', 'Бета-версия пока недоступна.', 'ベータ版はまだ利用できません。', '베타는 아직 제공되지 않습니다.'],
    'Language': ['Language', '语言', '語言', 'Idioma', 'भाषा', 'Langue', 'Idioma', 'Язык', '言語', '언어'],
    '© 2026 FaceAuth. All rights reserved.': ['© 2026 FaceAuth. All rights reserved.', '© 2026 FaceAuth。保留所有权利。', '© 2026 FaceAuth。保留所有權利。', '© 2026 FaceAuth. Todos los derechos reservados.', '© 2026 FaceAuth। सर्वाधिकार सुरक्षित।', '© 2026 FaceAuth. Tous droits réservés.', '© 2026 FaceAuth. Todos os direitos reservados.', '© 2026 FaceAuth. Все права защищены.', '© 2026 FaceAuth。無断転載を禁じます。', '© 2026 FaceAuth. 모든 권리 보유.'],
    'The world’s first Face ID for Mac': ['The world’s first Face ID for Mac', '世界首款 Mac Face ID', '世界首款 Mac Face ID', 'El primer Face ID para Mac del mundo', 'दुनिया का पहला Mac के लिए Face ID', 'Le premier Face ID pour Mac au monde', 'O primeiro Face ID para Mac do mundo', 'Первый в мире Face ID для Mac', '世界初の Mac 用 Face ID', '세계 최초의 Mac용 Face ID'],
    'Before Apple brought Face ID to Mac, we imagined what it could be.': ['Before Apple brought Face ID to Mac, we imagined what it could be.', '在 Apple 将 Face ID 带到 Mac 之前，我们想象过它的样子。', '在 Apple 將 Face ID 帶到 Mac 之前，我們想像過它會是什麼樣子。', 'Antes de que Apple llevara Face ID al Mac, imaginamos cómo podría ser.', 'Apple के Mac पर Face ID लाने से पहले हमने इसकी कल्पना की थी।', 'Avant qu’Apple apporte Face ID au Mac, nous avons imaginé ce que cela pourrait être.', 'Antes de a Apple trazer o Face ID para o Mac, imaginamos como ele poderia ser.', 'До появления Face ID на Mac мы представляли, каким он мог бы быть.', 'Apple が Mac に Face ID を搭載する前から、その可能性を思い描いていました。', 'Apple이 Mac에 Face ID를 도입하기 전부터 그 모습을 상상했습니다.'],
    'We built a seamless way to unlock your Mac with just a look.': ['We built a seamless way to unlock your Mac with just a look.', '我们打造了一种只需一眼即可无缝解锁 Mac 的方式。', '我們打造了一種只需一眼即可無縫解鎖 Mac 的方式。', 'Creamos una forma fluida de desbloquear tu Mac con una sola mirada.', 'हमने केवल एक नज़र से Mac अनलॉक करने का सहज तरीका बनाया है।', 'Nous avons créé un moyen fluide de déverrouiller votre Mac d’un simple regard.', 'Criamos uma forma simples de desbloquear o Mac com apenas um olhar.', 'Мы создали удобный способ разблокировать Mac одним взглядом.', '見るだけで Mac をスムーズにロック解除できる方法を実現しました。', '바라보기만 하면 Mac을 자연스럽게 잠금 해제할 수 있도록 만들었습니다.'],
    'Expanded': ['Expanded', '展开', '展開', 'Expandido', 'विस्तृत', 'Étendu', 'Expandido', 'Расширенный', '展開', '확장'],
    'Minimal': ['Minimal', '极简', '極簡', 'Minimalista', 'न्यूनतम', 'Minimal', 'Minimalista', 'Минималистичный', 'ミニマル', '미니멀'],
    'Haptic feedback': ['Haptic feedback', '触觉反馈', '觸覺回饋', 'Respuesta háptica', 'हैप्टिक फ़ीडबैक', 'Retour haptique', 'Feedback tátil', 'Тактильная обратная связь', '触覚フィードバック', '햅틱 피드백'],
    'Beautiful animations': ['Beautiful animations', '精美动画', '精美動畫', 'Animaciones atractivas', 'सुंदर एनिमेशन', 'De belles animations', 'Animações bonitas', 'Красивые анимации', '美しいアニメーション', '아름다운 애니메이션'],
    'Instant unlocks': ['Instant unlocks', '即时解锁', '即時解鎖', 'Desbloqueo instantáneo', 'तुरंत अनलॉक', 'Déverrouillage instantané', 'Desbloqueios instantâneos', 'Мгновенная разблокировка', '瞬時にロック解除', '즉시 잠금 해제'],
    'Lock screen ready': ['Lock screen ready', '锁屏就绪', '鎖定畫面就緒', 'Listo para la pantalla de bloqueo', 'लॉक स्क्रीन के लिए तैयार', 'Prêt pour l’écran verrouillé', 'Pronto para a tela bloqueada', 'Готово для экрана блокировки', 'ロック画面に対応', '잠금 화면 지원'],
    'Native': ['Native', '原生', '原生', 'Nativa', 'नेटिव', 'Native', 'Nativo', 'Нативное', 'ネイティブ', '네이티브'],
    'App': ['App', '应用', 'App', 'App', 'ऐप', 'App', 'App', 'Приложение', 'アプリ', '앱'],
    'Identities': ['Identities', '身份', '身分', 'Identidades', 'पहचान', 'Identités', 'Identidades', 'Идентичности', 'ID', '신원'],
    'A more natural way to unlock.': ['A more natural way to unlock.', '更自然的解锁方式。', '更自然的解鎖方式。', 'Una forma más natural de desbloquear.', 'अनलॉक करने का अधिक स्वाभाविक तरीका।', 'Une façon plus naturelle de déverrouiller.', 'Uma forma mais natural de desbloquear.', 'Более естественный способ разблокировки.', 'もっと自然なロック解除方法。', '더 자연스러운 잠금 해제 방법.'],
    'Just look.': ['Just look.', '看一眼即可。', '看一眼即可。', 'Solo mira.', 'बस देखें।', 'Il suffit de regarder.', 'Basta olhar.', 'Просто посмотрите.', '見るだけ。', '바라보기만 하세요.'],
    'Fast enough to feel instant.': ['Fast enough to feel instant.', '快到感觉即时完成。', '快到感覺即時完成。', 'Lo bastante rápido para parecer instantáneo.', 'इतना तेज़ कि तुरंत लगे।', 'Assez rapide pour sembler instantané.', 'Rápido o bastante para parecer instantâneo.', 'Достаточно быстро, чтобы казаться мгновенным.', '瞬時に感じるほど高速。', '즉시처럼 느껴질 만큼 빠릅니다.'],
    'Your face stays yours.': ['Your face stays yours.', '你的面孔始终属于你。', '你的臉始終屬於你。', 'Tu rostro sigue siendo tuyo.', 'आपका चेहरा आपका ही रहता है।', 'Votre visage reste le vôtre.', 'Seu rosto continua sendo seu.', 'Ваше лицо остаётся вашим.', 'あなたの顔はあなたのもの。', '얼굴 데이터는 온전히 당신의 것입니다.'],
    'More than one face.': ['More than one face.', '支持多个面孔。', '支援多個臉孔。', 'Más de un rostro.', 'एक से अधिक चेहरे।', 'Plusieurs visages.', 'Mais de um rosto.', 'Больше одного лица.', '複数の顔に対応。', '여러 얼굴을 지원합니다.'],
    "When it doesn't recognize you.": ["When it doesn't recognize you.", '无法识别时。', '無法辨識時。', 'Cuando no te reconoce.', 'जब यह आपको पहचान न पाए।', 'Lorsqu’il ne vous reconnaît pas.', 'Quando não reconhecer você.', 'Если вас не удалось распознать.', '認識されないとき。', '인식하지 못할 때.'],
    'Your face. Your Mac. Your privacy.': ['Your face. Your Mac. Your privacy.', '你的脸。你的 Mac。你的隐私。', '你的臉。你的 Mac。你的隱私。', 'Tu rostro. Tu Mac. Tu privacidad.', 'आपका चेहरा। आपका Mac। आपकी गोपनीयता।', 'Votre visage. Votre Mac. Votre vie privée.', 'Seu rosto. Seu Mac. Sua privacidade.', 'Ваше лицо. Ваш Mac. Ваша конфиденциальность.', 'あなたの顔。あなたの Mac。あなたのプライバシー。', '당신의 얼굴. 당신의 Mac. 당신의 개인정보.'],
    'Security starts with you': ['Security starts with you', '安全始于你', '安全始於你', 'La seguridad empieza contigo', 'सुरक्षा आपसे शुरू होती है', 'La sécurité commence avec vous', 'A segurança começa com você', 'Безопасность начинается с вас', 'セキュリティはあなたから', '보안은 당신으로부터 시작됩니다'],
    'Private by design': ['Private by design', '隐私优先设计', '隱私優先設計', 'Privado por diseño', 'डिज़ाइन से निजी', 'Privé par conception', 'Privado por design', 'Конфиденциальность заложена в дизайн', 'プライバシーを重視した設計', '개인정보 보호를 우선한 설계'],
    'Liveness Detection': ['Liveness Detection', '活体检测', '活體偵測', 'Detección de vitalidad', 'जीवंतता पहचान', 'Détection de présence réelle', 'Detecção de vivacidade', 'Проверка живого присутствия', 'ライブネス検出', '실시간 생체 감지'],
    'Local Processing': ['Local Processing', '本地处理', '本機處理', 'Procesamiento local', 'स्थानीय प्रोसेसिंग', 'Traitement local', 'Processamento local', 'Локальная обработка', 'ローカル処理', '로컬 처리'],
    'Ready to unlock with a look?': ['Ready to unlock with a look?', '准备好一眼解锁了吗？', '準備好一眼解鎖了嗎？', '¿Listo para desbloquear con una mirada?', 'एक नज़र से अनलॉक करने के लिए तैयार हैं?', 'Prêt à déverrouiller d’un regard ?', 'Pronto para desbloquear com um olhar?', 'Готовы разблокировать Mac одним взглядом?', '視線だけでロック解除する準備はできましたか？', '바라보기만 해서 잠금 해제할 준비가 되셨나요?'],
    'Download FaceAuth for Mac': ['Download FaceAuth for Mac', '下载 Mac 版 FaceAuth', '下載 Mac 版 FaceAuth', 'Descarga FaceAuth para Mac', 'Mac के लिए FaceAuth डाउनलोड करें', 'Télécharger FaceAuth pour Mac', 'Baixe o FaceAuth para Mac', 'Скачать FaceAuth для Mac', 'Mac 用 FaceAuth をダウンロード', 'Mac용 FaceAuth 다운로드']
  };
  const catalog = Object.fromEntries(Object.entries(translations).map(([key, values]) => [key, Object.fromEntries(languages.map(([, code], index) => [code, values[index]]))]));
  const originalText = new WeakMap();
  const originalAttributes = new WeakMap();
  const storageKey = 'faceauth-language';
  let selectedLanguage = languages.some(([, code]) => code === localStorage.getItem(storageKey)) ? localStorage.getItem(storageKey) : 'en';

  const translate = (source) => catalog[source]?.[selectedLanguage] || source;
  const keepWhitespace = (source, value) => source.replace(source.trim(), value);
  const ignored = (node) => ['SCRIPT', 'STYLE', 'NOSCRIPT', 'SVG'].includes(node.parentElement?.tagName);
  const translateText = (root) => {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) {
      const node = walker.currentNode;
      if (ignored(node)) continue;
      if (!originalText.has(node)) originalText.set(node, node.nodeValue);
      const source = originalText.get(node);
      const key = source.trim();
      if (key && catalog[key]) node.nodeValue = keepWhitespace(source, translate(key));
    }
  };
  const translateAttributes = () => {
    document.querySelectorAll('[aria-label], [placeholder], [title]').forEach((element) => {
      ['aria-label', 'placeholder', 'title'].forEach((attribute) => {
        if (!element.hasAttribute(attribute)) return;
        if (!originalAttributes.has(element)) originalAttributes.set(element, {});
        const values = originalAttributes.get(element);
        if (!values[attribute]) values[attribute] = element.getAttribute(attribute);
        element.setAttribute(attribute, translate(values[attribute]));
      });
    });
    if (!originalAttributes.has(document)) originalAttributes.set(document, { title: document.title });
    document.title = translate(originalAttributes.get(document).title);
  };
  const updateSelector = () => document.querySelectorAll('.language-selector').forEach((selector) => {
    const selectedIndex = languages.findIndex(([, code]) => code === selectedLanguage);
    const toggle = selector.querySelector('.language-toggle');
    const menu = selector.querySelector('.language-menu');
    toggle.textContent = languages[selectedIndex][0];
    menu.setAttribute('aria-label', translate('Language'));
    selector.dataset.language = selectedLanguage;
    menu.querySelectorAll('.language-option').forEach((option, index) => {
      option.textContent = languages[index][0];
      option.classList.toggle('is-selected', index === selectedIndex);
      option.setAttribute('aria-selected', String(index === selectedIndex));
    });
  });
  const apply = () => { translateText(document.body); translateAttributes(); document.documentElement.lang = selectedLanguage; updateSelector(); };

  document.querySelectorAll('.language-selector').forEach((selector) => {
    const toggle = selector.querySelector('.language-toggle');
    const menu = selector.querySelector('.language-menu');
    menu.querySelectorAll('.language-option').forEach((option) => option.addEventListener('click', () => {
      selectedLanguage = option.dataset.language;
      localStorage.setItem(storageKey, selectedLanguage);
      selector.classList.remove('is-open');
      toggle.setAttribute('aria-expanded', 'false');
      apply();
    }));
    toggle.addEventListener('click', () => {
      const isOpen = selector.classList.toggle('is-open');
      toggle.setAttribute('aria-expanded', String(isOpen));
    });
  });
  document.addEventListener('click', (event) => document.querySelectorAll('.language-selector.is-open').forEach((selector) => {
    if (!selector.contains(event.target)) { selector.classList.remove('is-open'); selector.querySelector('.language-toggle').setAttribute('aria-expanded', 'false'); }
  }));
  document.addEventListener('keydown', (event) => { if (event.key === 'Escape') document.querySelectorAll('.language-selector.is-open').forEach((selector) => selector.classList.remove('is-open')); });
  apply();
})();

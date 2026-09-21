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
    'Download FaceAuth for Mac': ['Download FaceAuth for Mac', '下载 Mac 版 FaceAuth', '下載 Mac 版 FaceAuth', 'Descarga FaceAuth para Mac', 'Mac के लिए FaceAuth डाउनलोड करें', 'Télécharger FaceAuth pour Mac', 'Baixe o FaceAuth para Mac', 'Скачать FaceAuth для Mac', 'Mac 用 FaceAuth をダウンロード', 'Mac용 FaceAuth 다운로드'],
    'Stay up to date with FaceAuth as development continues.': ['Stay up to date with FaceAuth as development continues.', '随着 FaceAuth 持续开发，及时了解最新进展。', '隨著 FaceAuth 持續開發，掌握最新進展。', 'Mantente al día con FaceAuth mientras continúa el desarrollo.', 'विकास जारी रहने के साथ FaceAuth की जानकारी से अपडेट रहें।', 'Restez informé de l’évolution de FaceAuth au fil du développement.', 'Acompanhe as novidades do FaceAuth enquanto o desenvolvimento continua.', 'Следите за обновлениями FaceAuth по мере продолжения разработки.', '開発が進む FaceAuth の最新情報をお届けします。', '개발이 계속되는 동안 FaceAuth의 최신 소식을 확인하세요.'],
    'FaceAuth is currently in development. No public beta or official release is available yet.': ['FaceAuth is currently in development. No public beta or official release is available yet.', 'FaceAuth 目前正在开发中。公开测试版或正式版尚未发布。', 'FaceAuth 目前正在開發中。公開測試版或正式版本尚未推出。', 'FaceAuth está actualmente en desarrollo. Todavía no hay una beta pública ni una versión oficial disponible.', 'FaceAuth अभी विकास में है। सार्वजनिक बीटा या आधिकारिक रिलीज़ अभी उपलब्ध नहीं है।', 'FaceAuth est actuellement en développement. Aucune bêta publique ni version officielle n’est encore disponible.', 'O FaceAuth está em desenvolvimento. Nenhuma versão beta pública ou oficial está disponível ainda.', 'FaceAuth находится в разработке. Публичная бета-версия или официальный выпуск пока недоступны.', 'FaceAuth は現在開発中です。公開ベータ版や正式版はまだ提供されていません。', 'FaceAuth는 현재 개발 중입니다. 공개 베타 또는 정식 버전은 아직 제공되지 않습니다.'],
    'Version 1.0 — In Development': ['Version 1.0 — In Development', '版本 1.0 — 开发中', '版本 1.0 — 開發中', 'Versión 1.0 — En desarrollo', 'संस्करण 1.0 — विकास में', 'Version 1.0 — En développement', 'Versão 1.0 — Em desenvolvimento', 'Версия 1.0 — В разработке', 'バージョン 1.0 — 開発中', '버전 1.0 — 개발 중'],
    'What is FaceAuth?': ['What is FaceAuth?', 'FaceAuth 是什么？', 'FaceAuth 是什麼？', '¿Qué es FaceAuth?', 'FaceAuth क्या है?', 'Qu’est-ce que FaceAuth ?', 'O que é o FaceAuth?', 'Что такое FaceAuth?', 'FaceAuth とは？', 'FaceAuth란 무엇인가요?'],
    'How does FaceAuth work?': ['How does FaceAuth work?', 'FaceAuth 如何工作？', 'FaceAuth 如何運作？', '¿Cómo funciona FaceAuth?', 'FaceAuth कैसे काम करता है?', 'Comment fonctionne FaceAuth ?', 'Como o FaceAuth funciona?', 'Как работает FaceAuth?', 'FaceAuth はどのように動作しますか？', 'FaceAuth는 어떻게 작동하나요?'],
    'Does FaceAuth work offline?': ['Does FaceAuth work offline?', 'FaceAuth 可以离线使用吗？', 'FaceAuth 可以離線使用嗎？', '¿FaceAuth funciona sin conexión?', 'क्या FaceAuth ऑफ़लाइन काम करता है?', 'FaceAuth fonctionne-t-il hors ligne ?', 'O FaceAuth funciona offline?', 'Работает ли FaceAuth офлайн?', 'FaceAuth はオフラインで動作しますか？', 'FaceAuth는 오프라인에서 작동하나요?'],
    'Does FaceAuth send my face to the cloud?': ['Does FaceAuth send my face to the cloud?', 'FaceAuth 会将我的面部信息发送到云端吗？', 'FaceAuth 會將我的臉部資訊傳送到雲端嗎？', '¿FaceAuth envía mi rostro a la nube?', 'क्या FaceAuth मेरा चेहरा क्लाउड पर भेजता है?', 'FaceAuth envoie-t-il mon visage dans le cloud ?', 'O FaceAuth envia meu rosto para a nuvem?', 'Отправляет ли FaceAuth моё лицо в облако?', 'FaceAuth は顔情報をクラウドに送信しますか？', 'FaceAuth는 얼굴을 클라우드로 보내나요?'],
    'Is FaceAuth safe?': ['Is FaceAuth safe?', 'FaceAuth 安全吗？', 'FaceAuth 安全嗎？', '¿Es seguro FaceAuth?', 'क्या FaceAuth सुरक्षित है?', 'FaceAuth est-il sûr ?', 'O FaceAuth é seguro?', 'Безопасен ли FaceAuth?', 'FaceAuth は安全ですか？', 'FaceAuth는 안전한가요?'],
    'Camera access isn’t working': ['Camera access isn’t working', '摄像头访问无法使用', '相機存取無法使用', 'El acceso a la cámara no funciona', 'कैमरा एक्सेस काम नहीं कर रहा', 'L’accès à la caméra ne fonctionne pas', 'O acesso à câmera não funciona', 'Доступ к камере не работает', 'カメラにアクセスできません', '카메라 접근이 작동하지 않습니다'],
    'FaceAuth isn’t recognizing me': ['FaceAuth isn’t recognizing me', 'FaceAuth 无法识别我', 'FaceAuth 無法辨識我', 'FaceAuth no me reconoce', 'FaceAuth मुझे पहचान नहीं रहा', 'FaceAuth ne me reconnaît pas', 'O FaceAuth não me reconhece', 'FaceAuth меня не распознаёт', 'FaceAuth が認識してくれません', 'FaceAuth가 저를 인식하지 못합니다'],
    'FaceAuth isn’t opening': ['FaceAuth isn’t opening', 'FaceAuth 无法打开', 'FaceAuth 無法開啟', 'FaceAuth no se abre', 'FaceAuth नहीं खुल रहा', 'FaceAuth ne s’ouvre pas', 'O FaceAuth não abre', 'FaceAuth не открывается', 'FaceAuth が開きません', 'FaceAuth가 열리지 않습니다'],
    'Make sure:': ['Make sure:', '请确认：', '請確認：', 'Asegúrate de lo siguiente:', 'सुनिश्चित करें:', 'Vérifiez que :', 'Certifique-se de que:', 'Убедитесь, что:', '次を確認してください：', '다음을 확인하세요:'],
    'Try:': ['Try:', '尝试：', '請嘗試：', 'Prueba:', 'कोशिश करें:', 'Essayez :', 'Tente:', 'Попробуйте:', 'お試しください：', '다음을 시도하세요:'],
    'Open:': ['Open:', '打开：', '開啟：', 'Abre:', 'खोलें:', 'Ouvrez :', 'Abra:', 'Откройте:', '開く：', '열기:'],
    'Questions about FaceAuth?': ['Questions about FaceAuth?', '对 FaceAuth 有疑问？', '對 FaceAuth 有疑問？', '¿Tienes preguntas sobre FaceAuth?', 'FaceAuth के बारे में प्रश्न?', 'Des questions sur FaceAuth ?', 'Dúvidas sobre o FaceAuth?', 'Есть вопросы о FaceAuth?', 'FaceAuth について質問がありますか？', 'FaceAuth에 대해 궁금한 점이 있나요?'],
    'Suggested questions': ['Suggested questions', '推荐问题', '推薦問題', 'Preguntas sugeridas', 'सुझाए गए प्रश्न', 'Questions suggérées', 'Perguntas sugeridas', 'Предлагаемые вопросы', 'おすすめの質問', '추천 질문'],
    'Is my face data private?': ['Is my face data private?', '我的面部数据是私密的吗？', '我的臉部資料是私密的嗎？', '¿Mis datos faciales son privados?', 'क्या मेरा चेहरा डेटा निजी है?', 'Mes données faciales sont-elles privées ?', 'Meus dados faciais são privados?', 'Мои данные лица конфиденциальны?', '顔データはプライベートですか？', '얼굴 데이터는 비공개인가요?'],
    'Which Macs are supported?': ['Which Macs are supported?', '支持哪些 Mac？', '支援哪些 Mac？', '¿Qué Mac son compatibles?', 'कौन से Mac समर्थित हैं?', 'Quels Mac sont pris en charge ?', 'Quais Macs são compatíveis?', 'Какие Mac поддерживаются?', '対応している Mac は？', '어떤 Mac을 지원하나요?'],
    'Ask a question...': ['Ask a question...', '询问问题……', '詢問問題……', 'Haz una pregunta...', 'प्रश्न पूछें...', 'Posez une question...', 'Faça uma pergunta...', 'Задайте вопрос...', '質問してください…', '질문을 입력하세요...'],
    'Please complete this required field.': ['Please complete this required field.', '请填写此必填字段。', '請填寫此必填欄位。', 'Completa este campo obligatorio.', 'कृपया यह आवश्यक फ़ील्ड भरें।', 'Veuillez remplir ce champ obligatoire.', 'Preencha este campo obrigatório.', 'Заполните это обязательное поле.', '必須項目を入力してください。', '필수 항목을 입력하세요.'],
    "We couldn't submit your details. Please try again.": ["We couldn't submit your details. Please try again.", '无法提交你的信息。请重试。', '無法提交你的資料。請再試一次。', 'No se pudieron enviar tus datos. Inténtalo de nuevo.', 'आपकी जानकारी सबमिट नहीं हो सकी। कृपया फिर से प्रयास करें।', 'Impossible d’envoyer vos informations. Veuillez réessayer.', 'Não foi possível enviar seus dados. Tente novamente.', 'Не удалось отправить данные. Повторите попытку.', '情報を送信できませんでした。もう一度お試しください。', '정보를 제출하지 못했습니다. 다시 시도해 주세요.'],
    'First name': ['First name', '名字', '名字', 'Nombre', 'पहला नाम', 'Prénom', 'Nome', 'Имя', '名', '이름'],
    'Last name': ['Last name', '姓氏', '姓氏', 'Apellidos', 'अंतिम नाम', 'Nom', 'Sobrenome', 'Фамилия', '姓', '성'],
    'Email': ['Email', '电子邮件', '電子郵件', 'Correo electrónico', 'ईमेल', 'E-mail', 'E-mail', 'Электронная почта', 'メール', '이메일'],
    'Phone number': ['Phone number', '电话号码', '電話號碼', 'Número de teléfono', 'फ़ोन नंबर', 'Numéro de téléphone', 'Número de telefone', 'Номер телефона', '電話番号', '전화번호'],
    'Additional comments': ['Additional comments', '其他备注', '其他備註', 'Comentarios adicionales', 'अतिरिक्त टिप्पणियाँ', 'Commentaires supplémentaires', 'Comentários adicionais', 'Дополнительные комментарии', '追加コメント', '추가 의견'],
    'Send': ['Send', '发送', '傳送', 'Enviar', 'भेजें', 'Envoyer', 'Enviar', 'Отправить', '送信', '보내기'],
    '✦ Ask FaceAuth AI': ['✦ Ask FaceAuth AI', '✦ 询问 FaceAuth AI', '✦ 詢問 FaceAuth AI', '✦ Pregúntale a FaceAuth AI', '✦ FaceAuth AI से पूछें', '✦ Demander à FaceAuth AI', '✦ Pergunte ao FaceAuth AI', '✦ Спросить FaceAuth AI', '✦ FaceAuth AI に質問', '✦ FaceAuth AI에게 질문'],
    'FaceAuth is currently in beta.': ['FaceAuth is currently in beta.', 'FaceAuth 目前处于测试阶段。', 'FaceAuth 目前處於測試階段。', 'FaceAuth está actualmente en beta.', 'FaceAuth अभी बीटा में है।', 'FaceAuth est actuellement en bêta.', 'O FaceAuth está atualmente em beta.', 'FaceAuth сейчас находится на этапе беты.', 'FaceAuth は現在ベータ版です。', 'FaceAuth는 현재 베타 버전입니다.'],
    'You may encounter bugs or unexpected behavior while using FaceAuth, as some features are still being developed and refined.': ['You may encounter bugs or unexpected behavior while using FaceAuth, as some features are still being developed and refined.', '使用 FaceAuth 时可能会遇到错误或意外行为，因为部分功能仍在开发和完善中。', '使用 FaceAuth 時可能會遇到錯誤或非預期行為，因為部分功能仍在開發與完善中。', 'Puedes encontrar errores o comportamientos inesperados mientras usas FaceAuth, ya que algunas funciones aún están en desarrollo.', 'FaceAuth का उपयोग करते समय बग या अनपेक्षित व्यवहार हो सकता है क्योंकि कुछ सुविधाएँ अभी विकसित हो रही हैं।', 'FaceAuth peut présenter des bugs ou des comportements inattendus, car certaines fonctions sont encore en développement.', 'Você pode encontrar bugs ou comportamentos inesperados ao usar o FaceAuth, pois alguns recursos ainda estão em desenvolvimento.', 'При использовании FaceAuth возможны ошибки или неожиданное поведение, поскольку некоторые функции ещё разрабатываются.', '一部の機能は開発中のため、FaceAuth の使用中にバグや予期しない動作が発生する場合があります。', '일부 기능이 아직 개발 및 개선 중이므로 FaceAuth 사용 중 버그나 예상치 못한 동작이 발생할 수 있습니다.'],
    "Your Mac's normal password remains available as a fallback at all times.": ["Your Mac's normal password remains available as a fallback at all times.", '你的 Mac 常规密码始终可以作为备用方式使用。', '你的 Mac 一般密碼隨時都可以作為備用方式使用。', 'La contraseña normal de tu Mac siempre está disponible como alternativa.', 'आपका सामान्य Mac पासवर्ड हमेशा वैकल्पिक तरीके के रूप में उपलब्ध रहता है।', 'Le mot de passe habituel de votre Mac reste toujours disponible en secours.', 'A senha normal do seu Mac está sempre disponível como alternativa.', 'Обычный пароль Mac всегда доступен в качестве запасного варианта.', 'Mac の通常のパスワードはいつでも代替手段として使用できます。', 'Mac의 일반 비밀번호는 항상 대체 수단으로 사용할 수 있습니다.']
  };
  const catalog = Object.fromEntries(Object.entries(translations).map(([key, values]) => [key, Object.fromEntries(languages.map(([, code], index) => [code, values[index]]))]));
  const originalText = new WeakMap();
  const originalAttributes = new WeakMap();
  const storageKey = 'faceauth-language';
  let selectedLanguage = languages.some(([, code]) => code === localStorage.getItem(storageKey)) ? localStorage.getItem(storageKey) : 'en';
  let applying = false;

  const wordTranslations = {
    'zh-CN': { 'the': '这', 'is': '是', 'are': '是', 'and': '和', 'or': '或', 'your': '你的', 'you': '你', 'with': '与', 'for': '用于', 'from': '从', 'to': '到', 'in': '在', 'on': '在', 'of': '的', 'this': '这', 'that': '该', 'can': '可以', 'does': '是否', 'work': '工作', 'use': '使用', 'camera': '摄像头', 'face': '面部', 'data': '数据', 'privacy': '隐私', 'security': '安全', 'system': '系统', 'settings': '设置', 'password': '密码', 'available': '可用', 'required': '需要', 'yes': '是', 'no': '不', 'not': '不', 'what': '什么', 'how': '如何', 'why': '为什么', 'when': '何时', 'where': '哪里', 'please': '请', 'more': '更多', 'about': '关于', 'next': '接下来' },
    'zh-TW': { 'the': '這', 'is': '是', 'are': '是', 'and': '和', 'or': '或', 'your': '你的', 'you': '你', 'with': '與', 'for': '用於', 'from': '從', 'to': '到', 'in': '在', 'on': '在', 'of': '的', 'this': '這', 'that': '該', 'can': '可以', 'does': '是否', 'work': '運作', 'use': '使用', 'camera': '相機', 'face': '臉部', 'data': '資料', 'privacy': '隱私', 'security': '安全性', 'system': '系統', 'settings': '設定', 'password': '密碼', 'available': '可用', 'required': '需要', 'yes': '是', 'no': '不', 'not': '不', 'what': '什麼', 'how': '如何', 'why': '為什麼', 'when': '何時', 'where': '哪裡', 'please': '請', 'more': '更多', 'about': '關於', 'next': '接下來' },
    es: { 'the': 'el', 'is': 'es', 'are': 'son', 'and': 'y', 'or': 'o', 'your': 'tu', 'you': 'tú', 'with': 'con', 'for': 'para', 'from': 'de', 'to': 'a', 'in': 'en', 'on': 'en', 'of': 'de', 'this': 'esto', 'that': 'eso', 'can': 'puede', 'does': 'hace', 'work': 'funciona', 'use': 'usar', 'camera': 'cámara', 'face': 'rostro', 'data': 'datos', 'privacy': 'privacidad', 'security': 'seguridad', 'system': 'sistema', 'settings': 'ajustes', 'password': 'contraseña', 'available': 'disponible', 'required': 'necesario', 'yes': 'sí', 'no': 'no', 'not': 'no', 'what': 'qué', 'how': 'cómo', 'why': 'por qué', 'when': 'cuándo', 'where': 'dónde', 'please': 'por favor', 'more': 'más', 'about': 'sobre', 'next': 'siguiente' },
    hi: { 'the': 'यह', 'is': 'है', 'are': 'हैं', 'and': 'और', 'or': 'या', 'your': 'आपका', 'you': 'आप', 'with': 'के साथ', 'for': 'के लिए', 'from': 'से', 'to': 'तक', 'in': 'में', 'on': 'पर', 'of': 'का', 'this': 'यह', 'that': 'वह', 'can': 'सकता है', 'does': 'करता है', 'work': 'काम', 'use': 'उपयोग', 'camera': 'कैमरा', 'face': 'चेहरा', 'data': 'डेटा', 'privacy': 'गोपनीयता', 'security': 'सुरक्षा', 'system': 'सिस्टम', 'settings': 'सेटिंग्स', 'password': 'पासवर्ड', 'available': 'उपलब्ध', 'required': 'आवश्यक', 'yes': 'हाँ', 'no': 'नहीं', 'not': 'नहीं', 'what': 'क्या', 'how': 'कैसे', 'why': 'क्यों', 'when': 'कब', 'where': 'कहाँ', 'please': 'कृपया', 'more': 'अधिक', 'about': 'के बारे में', 'next': 'अगला' },
    fr: { 'the': 'le', 'is': 'est', 'are': 'sont', 'and': 'et', 'or': 'ou', 'your': 'votre', 'you': 'vous', 'with': 'avec', 'for': 'pour', 'from': 'de', 'to': 'à', 'in': 'dans', 'on': 'sur', 'of': 'de', 'this': 'ce', 'that': 'cela', 'can': 'peut', 'does': 'fait', 'work': 'fonctionne', 'use': 'utiliser', 'camera': 'caméra', 'face': 'visage', 'data': 'données', 'privacy': 'confidentialité', 'security': 'sécurité', 'system': 'système', 'settings': 'réglages', 'password': 'mot de passe', 'available': 'disponible', 'required': 'requis', 'yes': 'oui', 'no': 'non', 'not': 'ne', 'what': 'quoi', 'how': 'comment', 'why': 'pourquoi', 'when': 'quand', 'where': 'où', 'please': 'veuillez', 'more': 'plus', 'about': 'à propos', 'next': 'suivant' },
    pt: { 'the': 'o', 'is': 'é', 'are': 'são', 'and': 'e', 'or': 'ou', 'your': 'seu', 'you': 'você', 'with': 'com', 'for': 'para', 'from': 'de', 'to': 'para', 'in': 'em', 'on': 'em', 'of': 'de', 'this': 'este', 'that': 'isso', 'can': 'pode', 'does': 'faz', 'work': 'funciona', 'use': 'usar', 'camera': 'câmera', 'face': 'rosto', 'data': 'dados', 'privacy': 'privacidade', 'security': 'segurança', 'system': 'sistema', 'settings': 'ajustes', 'password': 'senha', 'available': 'disponível', 'required': 'necessário', 'yes': 'sim', 'no': 'não', 'not': 'não', 'what': 'o que', 'how': 'como', 'why': 'por que', 'when': 'quando', 'where': 'onde', 'please': 'por favor', 'more': 'mais', 'about': 'sobre', 'next': 'próximo' },
    ru: { 'the': 'этот', 'is': 'есть', 'are': 'являются', 'and': 'и', 'or': 'или', 'your': 'ваш', 'you': 'вы', 'with': 'с', 'for': 'для', 'from': 'из', 'to': 'к', 'in': 'в', 'on': 'на', 'of': 'из', 'this': 'это', 'that': 'тот', 'can': 'может', 'does': 'делает', 'work': 'работает', 'use': 'использовать', 'camera': 'камера', 'face': 'лицо', 'data': 'данные', 'privacy': 'конфиденциальность', 'security': 'безопасность', 'system': 'система', 'settings': 'настройки', 'password': 'пароль', 'available': 'доступен', 'required': 'требуется', 'yes': 'да', 'no': 'нет', 'not': 'не', 'what': 'что', 'how': 'как', 'why': 'почему', 'when': 'когда', 'where': 'где', 'please': 'пожалуйста', 'more': 'больше', 'about': 'о', 'next': 'далее' },
    ja: { 'the': 'この', 'is': 'です', 'are': 'です', 'and': 'と', 'or': 'または', 'your': 'あなたの', 'you': 'あなた', 'with': 'と', 'for': '用', 'from': 'から', 'to': 'へ', 'in': 'で', 'on': '上', 'of': 'の', 'this': 'この', 'that': 'その', 'can': 'できます', 'does': 'します', 'work': '動作', 'use': '使用', 'camera': 'カメラ', 'face': '顔', 'data': 'データ', 'privacy': 'プライバシー', 'security': 'セキュリティ', 'system': 'システム', 'settings': '設定', 'password': 'パスワード', 'available': '利用可能', 'required': '必要', 'yes': 'はい', 'no': 'いいえ', 'not': 'ない', 'what': '何', 'how': '方法', 'why': 'なぜ', 'when': 'いつ', 'where': 'どこ', 'please': 'ください', 'more': 'もっと', 'about': 'について', 'next': '次' },
    ko: { 'the': '이', 'is': '입니다', 'are': '입니다', 'and': '및', 'or': '또는', 'your': '당신의', 'you': '사용자', 'with': '와 함께', 'for': '용', 'from': '에서', 'to': '으로', 'in': '에서', 'on': '에', 'of': '의', 'this': '이', 'that': '그', 'can': '할 수 있습니다', 'does': '합니다', 'work': '작동', 'use': '사용', 'camera': '카메라', 'face': '얼굴', 'data': '데이터', 'privacy': '개인정보 보호', 'security': '보안', 'system': '시스템', 'settings': '설정', 'password': '비밀번호', 'available': '사용 가능', 'required': '필요', 'yes': '예', 'no': '아니요', 'not': '않습니다', 'what': '무엇', 'how': '방법', 'why': '왜', 'when': '언제', 'where': '어디', 'please': '하세요', 'more': '더', 'about': '정보', 'next': '다음' }
  };

  const translateWords = (source) => {
    if (selectedLanguage === 'en') return source;
    const protectedTerms = [];
    const protectedSource = source.replace(/FaceAuth|macOS|Mac|Face ID|Touch ID|Apple|Windows|Linux|Wi-Fi|iPhone|Sequoia/g, (term) => {
      protectedTerms.push(term);
      return `\u0000${protectedTerms.length - 1}\u0000`;
    });
    const words = wordTranslations[selectedLanguage] || {};
    const translated = protectedSource.replace(/\b[A-Za-z][A-Za-z'-]*\b/g, (word) => words[word.toLowerCase()] || word);
    return translated.replace(/\u0000(\d+)\u0000/g, (_, index) => protectedTerms[Number(index)]);
  };
  const translate = (source) => catalog[source]?.[selectedLanguage] || translateWords(source);
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
      if (key) node.nodeValue = keepWhitespace(source, translate(key));
    }
  };
  const translateAttributes = () => {
    document.querySelectorAll('[aria-label], [placeholder], [title], img[alt]').forEach((element) => {
      ['aria-label', 'placeholder', 'title', 'alt'].forEach((attribute) => {
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
    if (toggle.textContent !== languages[selectedIndex][0]) toggle.textContent = languages[selectedIndex][0];
    if (menu.getAttribute('aria-label') !== translate('Language')) menu.setAttribute('aria-label', translate('Language'));
    if (selector.dataset.language !== selectedLanguage) selector.dataset.language = selectedLanguage;
    menu.querySelectorAll('.language-option').forEach((option, index) => {
      if (option.textContent !== languages[index][0]) option.textContent = languages[index][0];
      option.classList.toggle('is-selected', index === selectedIndex);
      option.setAttribute('aria-selected', String(index === selectedIndex));
    });
  });
  const apply = () => {
    if (applying) return;
    applying = true;
    translateText(document.body);
    translateAttributes();
    document.documentElement.lang = selectedLanguage;
    updateSelector();
    applying = false;
  };

  const createSelector = (navInner) => {
    let actions = navInner.querySelector(':scope > .nav-actions');
    if (!actions) {
      actions = document.createElement('div');
      actions.className = 'nav-actions';
      Array.from(navInner.children).slice(1).forEach((child) => actions.append(child));
      navInner.append(actions);
    }
    let selector = actions.querySelector('.language-selector');
    if (selector) return selector;
    selector = document.createElement('div');
    selector.className = 'language-selector';
    const toggle = document.createElement('button');
    toggle.className = 'language-toggle';
    toggle.type = 'button';
    toggle.setAttribute('aria-expanded', 'false');
    toggle.setAttribute('aria-haspopup', 'listbox');
    const menu = document.createElement('div');
    menu.className = 'language-menu';
    menu.setAttribute('role', 'listbox');
    languages.forEach(([label, code], index) => {
      const option = document.createElement('button');
      option.className = `language-option${index === 0 ? ' is-selected' : ''}`;
      option.type = 'button';
      option.dataset.language = code;
      option.setAttribute('role', 'option');
      option.setAttribute('aria-selected', String(index === 0));
      option.textContent = label;
      menu.append(option);
    });
    selector.append(toggle, menu);
    actions.insertBefore(selector, actions.firstChild);
    return selector;
  };

  document.querySelectorAll('body > nav .nav-inner').forEach(createSelector);
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
  const observer = new MutationObserver((mutations) => {
    if (selectedLanguage === 'en' || applying) return;
    applying = true;
    mutations.forEach((mutation) => mutation.addedNodes.forEach((node) => {
      if (node.nodeType === Node.ELEMENT_NODE || node.nodeType === Node.TEXT_NODE) translateText(node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement);
    }));
    translateAttributes();
    updateSelector();
    applying = false;
  });
  apply();
  observer.observe(document.body, { childList: true, subtree: true });
  window.FaceAuthI18n = { translate, apply, getLanguage: () => selectedLanguage };
})();

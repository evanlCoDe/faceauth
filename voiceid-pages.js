(() => {
  if (new URLSearchParams(location.search).get('product') !== 'voice') return;

  const pageName = location.pathname.split('/').pop();
  const pageTitle = {
    'faq.html': 'VoiceID — Frequently Asked Questions',
    'support.html': 'VoiceID — Support',
    'release-notes.html': 'VoiceID — Release Notes',
    'release-notes-web.html': 'VoiceID — Web Release Notes'
  }[pageName];
  if (!pageTitle) return;

  document.title = pageTitle;
  document.body.dataset.product = 'voice';
  document.querySelectorAll('.eyebrow').forEach((eyebrow) => {
    eyebrow.textContent = 'VoiceID';
  });

  document.querySelectorAll('.brand').forEach((brand) => {
    const logo = brand.querySelector('img');
    const link = brand.querySelector('.logo');
    if (logo) {
      logo.src = 'voiceid_white.png';
      logo.alt = 'VoiceID logo';
    }
    if (link) {
      link.textContent = 'VoiceID';
      link.href = 'index.html?product=voice#top';
    }
  });

  document.querySelectorAll('.footer-brand').forEach((brand) => {
    brand.textContent = 'VoiceID';
  });
  document.querySelectorAll('.footer-title').forEach((title) => {
    title.textContent = 'VoiceID for Mac';
  });
  document.querySelectorAll('.footer-copyright').forEach((copyright) => {
    copyright.innerHTML = '&copy; 2026 VoiceID. All rights reserved.';
  });
  document.querySelectorAll('a[href]').forEach((link) => {
    const href = link.getAttribute('href') || '';
    if (!/^(faq|support|release-notes|release-notes-web)\.html(?:$|[?#])/.test(href)) return;
    const url = new URL(href, location.href);
    url.searchParams.set('product', 'voice');
    link.href = `${url.pathname.split('/').pop()}${url.search}${url.hash}`;
  });
  document.querySelectorAll('.brand a.logo').forEach((link) => {
    link.href = 'index.html?product=voice#top';
  });
  const pageCopy = document.querySelector('main.page > .copy');
  if (pageCopy && pageName === 'faq.html') {
    pageCopy.replaceChildren(document.createTextNode('Voice authentication for '));
    const appleIcon = document.createElement('img');
    appleIcon.className = 'apple-icon';
    appleIcon.src = 'ChatGPT Image Sep 18, 2026, 08_46_49 AM.png';
    appleIcon.alt = 'Apple logo';
    pageCopy.append(appleIcon, document.createTextNode(' Mac.'));
  } else if (pageCopy && pageName === 'support.html') {
    pageCopy.textContent = 'Voice authentication support for Mac.';
  } else if (pageCopy && pageName === 'release-notes.html') {
    pageCopy.textContent = 'Stay up to date with VoiceID for Mac as development continues.';
  }

  const node = (tag, text) => {
    const element = document.createElement(tag);
    element.textContent = text;
    return element;
  };
  const appendFaqGroup = (container, heading, entries) => {
    container.appendChild(node('h2', heading));
    entries.forEach(([question, answer]) => {
      container.append(node('h3', question), node('p', answer));
    });
  };

  if (pageName === 'faq.html') {
    const faq = document.querySelector('.faq-content');
    if (!faq) return;
    const faqNavigation = faq.querySelector('nav');
    faq.replaceChildren(...(faqNavigation ? [faqNavigation] : []));
    appendFaqGroup(faq, 'General', [
      ['What is VoiceID for Mac?', 'VoiceID is being developed as a way to unlock a Mac using an enrolled voice instead of typing a password each time. VoiceID is currently in development and is not available for download.'],
      ['How does VoiceID recognize my voice?', 'VoiceID is designed to compare live speech with an enrolled voice identity and begin the unlock flow when it recognizes an authorized speaker.'],
      ['Do I need to say a specific phrase?', 'VoiceID is being designed around natural speech rather than a fixed spoken passphrase. Final setup details will be shared when VoiceID is ready.'],
      ['Can VoiceID recognize more than one person?', 'VoiceID is being designed to support multiple enrolled voice identities, so authorized speakers can be recognized separately.'],
      ['What happens if VoiceID does not recognize me?', 'VoiceID is not intended to replace your Mac password. Your normal Mac sign-in method remains the fallback if voice recognition is unavailable.']
    ]);
    appendFaqGroup(faq, 'Voice Enrollment & Use', [
      ['How do I enroll my voice?', 'Voice enrollment will be part of the VoiceID for Mac setup. The enrollment steps and controls will be documented when the app is ready.'],
      ['Can I remove or disable an enrolled voice?', 'VoiceID is being designed with controls to manage enrolled voice identities, including disabling an identity without deleting it.'],
      ['Do I need to speak directly into my Mac?', 'VoiceID is intended to listen through a built-in or compatible external microphone. The best distance and acoustic conditions will be explained in the setup guide.'],
      ['Which microphone does VoiceID use?', 'VoiceID is being designed to work with a built-in or compatible external microphone. Supported inputs will be confirmed in the setup guide.'],
      ['Can VoiceID unlock my Mac from a recording?', 'VoiceID is being designed to verify live speech rather than accept a recording. Its final security behavior will be described when the product is available.'],
      ['Will VoiceID work in a noisy room?', 'Background noise can affect speech recognition. VoiceID setup guidance will explain supported microphone and environmental conditions.']
    ]);
    appendFaqGroup(faq, 'Privacy & Security', [
      ['Is my voice data private?', 'VoiceID is designed to process voice recognition on your Mac and keep voice biometric information close to your device. Final data-handling details will be published before release.'],
      ['Does VoiceID send my voice to the cloud?', 'VoiceID is being developed with local voice processing in mind. The final privacy documentation will explain exactly what data is processed and where.'],
      ['Does VoiceID need an internet connection?', 'VoiceID is being designed for on-device voice recognition. Its final network requirements will be confirmed with the release.'],
      ['Is VoiceID as secure as Apple’s built-in biometrics?', 'VoiceID is an independently developed software project and should not be treated as equivalent to Apple’s dedicated biometric hardware. Your Mac password remains available as a fallback.'],
      ['Does VoiceID replace my Mac password?', 'No. VoiceID is intended as an additional way to unlock your Mac; the normal Mac password remains available.']
    ]);
    appendFaqGroup(faq, 'Mac Compatibility & Availability', [
      ['Which Macs will support VoiceID?', 'VoiceID is being built for Mac. Supported macOS versions, processors, and microphone requirements will be published when the app is ready.'],
      ['Does VoiceID work on Windows or Linux?', 'VoiceID for Mac is being developed specifically for macOS. Windows and Linux support is not currently planned.'],
      ['Is VoiceID available now?', 'Not yet. VoiceID for Mac is in development. Join the VoiceID waitlist from the main page to hear when it is ready.'],
      ['Where can I get VoiceID support?', 'Visit the VoiceID Support page for microphone, setup, privacy, and availability guidance.']
    ]);
  } else if (pageName === 'support.html') {
    const support = document.querySelector('.legal-content');
    if (!support) return;
    support.replaceChildren(
      node('h2', 'Need help with VoiceID for Mac?'),
      node('p', 'VoiceID is in development. This guide covers common microphone, enrollment, privacy, and availability questions.'),
      node('h2', 'VoiceID isn’t recognizing my voice'),
      node('p', 'When VoiceID is available, check that:'),
      (() => {
        const list = document.createElement('ul');
        [
          'A built-in or compatible external microphone is connected and selected.',
          'VoiceID has microphone access in macOS Privacy & Security settings.',
          'You are speaking clearly and the microphone is not obstructed.',
          'Background noise is low enough for speech to be heard.',
          'Your enrolled voice identity is enabled.'
        ].forEach((item) => list.appendChild(node('li', item)));
        return list;
      })(),
      node('p', 'You can use your normal Mac password if voice recognition does not work.'),
      node('h2', 'Microphone access isn’t working'),
      node('p', 'Open System Settings → Privacy & Security → Microphone and allow VoiceID to use the microphone. Also check that the intended input device is selected in macOS.'),
      node('h2', 'I can’t enroll or manage a voice'),
      node('p', 'Voice enrollment and identity controls will be available in VoiceID for Mac. The setup guide will explain how to enroll, disable, or remove an identity when the app is ready.'),
      node('h2', 'When will VoiceID be available?'),
      node('p', 'VoiceID for Mac is currently in development. Join the VoiceID waitlist from the main page for availability updates.')
    );
  } else if (pageName === 'release-notes.html') {
    const notes = document.querySelector('.legal-content');
    if (!notes) return;
    notes.replaceChildren(
      node('h2', 'VoiceID for Mac — In Development'),
      node('p', 'VoiceID is being developed as a private, voice-based way to unlock your Mac. It is not yet available for download.'),
      node('h3', 'App Release Notes'),
      node('h4', 'Voice Authentication'),
      (() => {
        const list = document.createElement('ul');
        [
          'Developing voice recognition for enrolled speakers.',
          'Designing voice enrollment and controls for multiple identities.',
          'Building toward live-speech verification and on-device processing.',
          'Keeping the normal Mac password available as a fallback.'
        ].forEach((item) => list.appendChild(node('li', item)));
        return list;
      })(),
      node('h3', 'Availability'),
      node('p', 'VoiceID for Mac remains in development. Availability and supported Mac requirements will be announced when they are confirmed.')
    );
  } else if (pageName === 'release-notes-web.html') {
    const copy = document.querySelector('main.page > .copy');
    if (copy) copy.textContent = 'Voice authentication for Mac.';
    const supportingCopy = document.querySelectorAll('main.page > .copy')[1];
    if (supportingCopy) supportingCopy.textContent = 'Stay up to date with improvements to the VoiceID for Mac website.';
    const meta = document.querySelector('.release-meta');
    if (meta) {
      meta.querySelector('p')?.replaceChildren(document.createTextNode('VoiceID for Mac Website'));
    }
    const list = document.querySelector('.release-list');
    if (!list) return;
    list.setAttribute('aria-label', 'VoiceID website release updates');
    const updates = [
      ['VoiceID Product Switcher', 'Added a FaceAuth for Mac and VoiceID for Mac switcher while preserving the shared website experience.'],
      ['VoiceID Section', 'Added a VoiceID for Mac section describing voice authentication, privacy goals, voice identities, and current development status.'],
      ['VoiceID AI', 'Updated the shared assistant with VoiceID-specific labels, suggested questions, and answers about voice recognition and authentication.'],
      ['VoiceID Media', 'Added VoiceID-specific preview media for expanded and minimal interface states.'],
      ['VoiceID Help Content', 'Added VoiceID-specific FAQ, Support, and Release Notes content for voice enrollment, microphone setup, privacy, and availability.']
    ];
    list.replaceChildren();
    updates.forEach(([heading, description]) => {
      const article = document.createElement('article');
      article.className = 'release-item';
      article.append(node('h3', heading), node('p', description));
      list.appendChild(article);
    });
  }

  document.querySelectorAll('#beta-modal-overlay').forEach((overlay) => {
    const heading = overlay.querySelector('h2');
    const paragraphs = overlay.querySelectorAll('p');
    if (heading) heading.textContent = 'VoiceID for Mac is in development.';
    if (paragraphs[0]) paragraphs[0].textContent = 'VoiceID is being developed to make voice authentication feel simple, private, and seamless on Mac.';
    if (paragraphs[1]) paragraphs[1].textContent = 'Your normal Mac sign-in method remains available.';
  });
})();

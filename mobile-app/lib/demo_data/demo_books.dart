// Demo/sample book — there is no books backend at all (no Supabase table),
// so unlike posts/comments/marketplace listings this has nothing real to be
// replaced by. Kept here for reference/tests only; findBook() in
// models/book.dart no longer searches it, so the Book Reader has no content
// until a real books backend exists.
import 'package:flutter/material.dart';

import '../models/book.dart';

final mockBooks = [
  Book(
    id: 'b1',
    title: 'The Ember Throne',
    authorName: 'Adriana Voss',
    subtitle: 'A Tale of Fire and Forgotten Kings',
    coverColor: const Color(0xFF3D2B6B),
    coverTextColor: const Color(0xFFE8C49A),
    pages: [
      // Cover
      const BookPage(type: BookPageType.cover),

      // Title page
      const BookPage(
        type: BookPageType.titlePage,
        content: 'The Ember Throne\n\nA Tale of Fire and Forgotten Kings\n\nAdriana Voss',
      ),

      // Introduction (i, ii …)
      const BookPage(
        type: BookPageType.introduction,
        content:
            'In the age before maps, when the world was still being named, '
            'there existed a throne carved from the first cinder of creation. '
            'Kings came and kings fell, but the throne endured — patient as '
            'stone, hungry as flame.\n\n'
            'This book began as a single image: a girl standing before a door '
            'she was forbidden to open. Everything that follows is my attempt '
            'to understand why she opened it anyway.\n\n'
            'I owe debts to many readers, critics, and dreamers who shaped '
            'these pages. Most of all I owe a debt to the stories that kept '
            'me company in the dark.',
      ),
      const BookPage(
        type: BookPageType.introduction,
        content:
            'A note on the world-building: The Kaleth Empire is not a metaphor '
            'for any single historical civilisation, though it borrows freely '
            'from many. The magic system — Ember-weaving — follows rules '
            'internal to the story. Where those rules bend, the story bends '
            'with them.\n\n'
            'Readers sensitive to depictions of loss, grief, and political '
            'violence should be aware that these themes appear throughout.',
      ),

      // Chapters (1, 2, 3 …)
      const BookPage(
        type: BookPageType.chapter,
        chapterTitle: 'Chapter One — The Summons',
        content:
            'The letter arrived on a morning that smelled of rain and old iron.\n\n'
            'Sera did not open it at first. Letters from the capital had a '
            'weight that ordinary envelopes could not contain — as though the '
            'parchment itself had absorbed the ambitions of every hand it '
            'passed through. She set it on the windowsill and brewed tea '
            'instead, watching the paper the way one watches a spider '
            'discovered on a ceiling: uncertain whether to act.\n\n'
            '"You should read it," said her mother, not looking up from her '
            'mending.\n\n'
            '"I know what it says."\n\n'
            '"Then reading it can\'t hurt."\n\n'
            'Sera opened the letter. She read it twice. Then she folded it '
            'precisely along its original creases and slid it under her '
            'mattress, where she kept the things she did not want to think '
            'about.\n\n'
            'The Ember Throne had chosen her.',
      ),
      const BookPage(
        type: BookPageType.chapter,
        chapterTitle: 'Chapter Two — The Road South',
        content:
            'They left before sunrise, as the imperial decree required. Sera '
            'had packed little — two changes of clothes, the knife her father '
            'had given her, and a book of maps she had never managed to finish.\n\n'
            'The road to Kaleth wound through the Ashwood, three days of '
            'silver birch and silence. Her escort was a single soldier named '
            'Brek, who rode with the posture of a man who had spent too long '
            'carrying something heavy.\n\n'
            '"Do you know why they chose me?" Sera asked on the first '
            'evening, when they had made camp by a stream that moved with '
            'quiet urgency.\n\n'
            'Brek poked the fire. "The Throne chooses. We don\'t ask."\n\n'
            '"That\'s not an answer."\n\n'
            '"No," he agreed. "It isn\'t."',
      ),
      const BookPage(
        type: BookPageType.chapter,
        chapterTitle: 'Chapter Three — Kaleth',
        content:
            'The city rose from the plain like a fist. Sera had seen drawings, '
            'but drawings lied about scale — they could not capture the way the '
            'towers caught the afternoon light and turned it amber, or the '
            'particular hum of ten thousand people living on top of each other.\n\n'
            'They passed through four gates, each guarded by soldiers in red '
            'and black. At the fourth gate a woman in grey robes stepped '
            'forward and studied Sera with the patient attention of a jeweller '
            'examining a stone.\n\n'
            '"You\'re younger than the last one," the woman said.\n\n'
            '"The last what?"\n\n'
            '"Candidate." She turned and walked into the city without further '
            'explanation. Sera looked at Brek.\n\n'
            '"Follow her," he said.',
      ),

      // Glossary
      const BookPage(
        type: BookPageType.glossary,
        chapterTitle: 'Glossary',
        content:
            'Ashwood — The dense forest separating the outer provinces from '
            'the Kaleth lowlands. Named for the pale bark of its dominant '
            'tree species.\n\n'
            'Ember-weaving — The art of drawing on residual heat stored in '
            'materials to produce light, warmth, or kinetic force. Practitioners '
            'are called Weavers.\n\n'
            'Kaleth — Capital of the Kaleth Empire, population estimated at '
            'four hundred thousand at the time of the novel.\n\n'
            'The Throne — Formally the Ember Throne; the seat of imperial '
            'power, believed to be sentient by adherents of the Cinder Faith.\n\n'
            'Warden — Imperial official responsible for identifying and '
            'transporting Throne candidates from the provinces.',
      ),

      // References
      const BookPage(
        type: BookPageType.references,
        chapterTitle: 'References & Acknowledgements',
        content:
            'Historical inspiration drawn from:\n'
            '— Ibn Battuta, Travels (14th century)\n'
            '— Procopius, Secret History (6th century)\n'
            '— Le Guin, Ursula K., The Left Hand of Darkness (1969)\n\n'
            'Research assistance: Dr. Mara Osei (material culture), '
            'Prof. Jan Witek (fire chemistry).\n\n'
            'My editor Lucia Reyes, who asked the hard questions.\n'
            'My agent Daniel Park, who kept asking.\n'
            'My family, who stopped asking and started believing.',
      ),

      // Back cover
      const BookPage(
        type: BookPageType.backCover,
        content:
            'A luminous debut of ambition and fire.\n'
            '— The Chronicle Review\n\n'
            '"Voss writes with the confidence of someone who has lived '
            'inside this world for years."\n'
            '— Meridian Books Quarterly\n\n'
            'www.adrianavoss.com\n\n'
            'ISBN 978-0-000-00000-0',
      ),
    ],
  ),
];

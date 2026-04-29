from pathlib import Path
path = Path(r'c:\Users\Tayyab\Desktop\Fultter\aqua_talk\lib\screens\chats\chat_screen.dart')
text = path.read_text(encoding='utf-8')
old = '''          ),
        ],
      ),
    );
  }
}'''
new = '''          ),
        ],
      ),
    );
      },
    );
  }
}'''
if old not in text:
    raise SystemExit('Old block not found')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
print('patched')

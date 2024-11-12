# 签名流程

1. 签名
```bash
codesign --force --deep --sign "ReminderGenerator" ./ReminderGenerator-Bundle/reminder_app.app 
```

2. 校验
```bash
codesign --verify --deep --strict ./ReminderGenerator-Bundle/reminder_app.app 
```

3. dmg制作
```bash
ln -s /Applications "./ReminderGenerator-Bundle/Applications"

hdiutil create -volname "Track" \
               -srcfolder ReminderGenerator-Bundle \
               -ov -format UDZO \
               ReminderGenerator.dmg
```
source /root/.bashrc
cd backend
pub get
pub run build_runner build
killall dart
dart bin/main.dart > backend.log &

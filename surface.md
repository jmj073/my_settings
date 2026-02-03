# Surface Pro 7+ i5

surface pro 7+를 세팅하기 위한 가이드이다. feature는 다음과 같다.

+ **Fedora 43**: 43이 최신 버전이다.
+ **desktop environment**:
  + **GNOME**: 기본 DE다.
  + **phosh**: 모바일용 쉘이다. 해당 compositor로 접속하면 waydroid가 시작되고, 로그아웃하면 멈추게 세팅할것이다.
+ **steam**: 게임은 중요하다.

## Fedora 부팅 USB 만들기

[여기](https://www.fedoraproject.org/ko/workstation/download/)에 접속하여 x86_64용을 받아준다. fedora는 workstation, live(인터넷 설치가 아니라)를 설치해야 한다.

USB를 컴퓨터에 꽂고 해당 USB 디바이스 파일에 대해 예를 들어 다음과 같이 명령어를 실행해준다. 참고로 `lsblk` 명령으로 USB 디바이스를 확인할 수 있다.

```shell
sudo dd if=Fedora-Workstation-Live-x86_64-40-1.14.iso \
        of=/dev/sdb \
        bs=4M \
        status=progress \
        oflag=sync
```

USB로 복사 완료후 다음 명령어를 입력한다.

```shell
sync
```

## USB로 부팅

### UEFI 들어가기

\+ 볼륨 버튼을 누른채로 전원을 키면 UEFI로 접속된다.

### UEFI 설정

+ secure boot를 microsoft only에서 microsoft & 3rd party CA로 바꾼다.
+ USB 부팅의 우선순위를 최상단으로 옮긴다

### 파란 화면

USB로 부팅하면 파란 화면이 뜬다.

1. Continue Boot를 누른다.
2. Start Fedora-Workstation-Live를 누른다.

### Fedora 설치

언어는 한국어로 하는데, 키보드 배열은 그냥 us로 냅둔다. 설치 하고나서 초기 환경 설정에서 한국어 키보드 추가할 수 있다.

## surface kernel 설치

[여기](https://github.com/linux-surface/linux-surface/wiki/Installation-and-Setup#fedora)를 참고한다.

```shell
sudo dnf config-manager addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo
sudo dnf install --allowerasing kernel-surface iptsd libwacom-surface
sudo dnf install surface-secureboot
```

위 명령어를 실행후, 컴퓨터를 재시작한다.

`uname -r`을 입력해 surface 커널이 맞는지 확인한다.

## phosh 설치

```shell
sudo dnf install phosh phoc
```

+ `phosh`: 쉘
+ `phoc`: Wayland compositor

### Phosh 키보드 설정

phosh session으로 로그인하면 keyboard 활성화 하고, GNOME으로 로그인하면 keyboard를 비활성화한다.

`~.config/autostart-scripts/keyboard-handler.sh`에 다음 내용을 입력해주자.

```sh
#!/bin/bash

if [[ "$1" == "start" ]]; then
    sleep 5

    if pgrep -x "phosh" > /dev/null; then
        gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true
    else
        gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false
    fi
elif [[ "$1" == "stop" ]]; then
    gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false
fi
```

`~/.config/systemd/user/keyboard-handler.service`에 다음 내용을 입력해주자.

```ini
[Unit]
Description=Phosh Keyboard Toggle Handler
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/home/your_username/.config/autostart-scripts/keyboard-handler.sh start
ExecStop=/home/your_username/.config/autostart-scripts/keyboard-handler.sh stop
RemainAfterExit=yes

[Install]
WantedBy=graphical-session.target
```

이제 서비스를 활성화 시켜주자.

```shell
systemctl --user daemon-reload
systemctl --user enable keyboard-handler.service
```

## Waydroid 설치

### 설치

[참고](https://docs.waydro.id/usage/install-on-desktops#fedora).

```shell
sudo dnf install waydroid
```

`VANILLA`랑 `GAPPS`가 있는데, 기본값은 `VANILLA`이며, `GAPPS`에는 Google Play가 포함되어 있다.

```shell
sudo waydroid init -s GAPPS -c https://ota.waydro.id/system -v https://ota.waydro.id/vendor
```

### Google Play Certification

[참고](https://docs.waydro.id/faq/google-play-certification).

```shell
sudo waydroid shell -- sh -c "sqlite3 /data/data/*/*/gservices.db 'select value from main where name = \"android_id\";'"
```

명령어 실행하면 뜨는 id를 [이 사이트](https://www.google.com/android/uncertified)에 등록시킨다.

### Phosh 로그인할 때 시작하기

`~/.config/systemd/user/waydroid-phosh.service`에 다음 내용을 입력한다.

```ini
[Unit]
Description=Start Waydroid when logging into Phosh
After=graphical-session.target
ConditionEnvironment=DESKTOP_SESSION=phosh

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/waydroid session start
ExecStop=/usr/bin/waydroid session stop
TimeoutStartSec=0

[Install]
WantedBy=graphical-session.target
```

## 기타 설정

+ `iio-sensor-proxy`: 가속도/자이로 같은 센서를 표준 인터페이스로 노출하는 데몬

  ```shell
  sudo dnf install iio-sensor-proxy
  ```

  확인:

  ```shell
  monitor-sensor
  ```

+ 전원/배터리:

  ```shell
  sudo dnf install powertop
  ```

### 창 모양

창에 전체화면 버튼이랑 최소화 버튼이 기본적으로 뜨지 않는다. 이걸 설정하기 위해서 `gnome-tweaks`를 설치한다.

```shell
sudo dnf install gnome-tweaks
```

앱 이름은 아마 "기능 개선"이라고 뜰 것이다.

`창 -> 제목 표시줄 단추`에서 "최대화"와 "최소화"를 켜준다.

근데 다시 Phosh로 로그인하면 Phosh가 꺼버리는 경향이 있음. Phosh 로그인 했다가 다시 GNOME가면 버튼 사라져 있음.

### suspend

phosh 사용할때 가끔씩 suspend 상태에서 혼자서 화면이 껐다 켜짐. 아직 못고침.

### Steam

steam은 flatpak으로 설치하자. flatpak이란, "리눅스용 앱 컨테이너/패키지 시스템"이다. 다음과 같은 특징이 있다:

+ 앱을 **자기 런타임(라이브러리 묶음)** 과 함께 배포
+ 배포판(Fedora, Ubuntu 등)에 덜 의존
+ `/usr`를 더럽히지 않음
+ 앱 간 충돌 최소화

```shell
sudo dnf install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.valvesoftware.Steam
```

### neovim

```shell
sudo dnf install neovim
```

### chrome

chrome은 브라우저에서 다운로드받아 설치한다.

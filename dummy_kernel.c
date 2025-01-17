
void kernel_main(void) {
    char *video_memory = (char *)0xB8000; // 텍스트 모드 비디오 메모리 시작 주소
    const char *message = "Hello from the dummy kernel!";
    int i = 0;

    // 메시지 출력
    while (message[i] != '\0') {
        video_memory[i * 2] = message[i];    // 문자
        video_memory[i * 2 + 1] = 0x07;      // 속성 (흰색 텍스트, 검은 배경)
        i++;
    }

    // 무한 루프 (커널 실행 중지 방지)
    while (1) {}
}

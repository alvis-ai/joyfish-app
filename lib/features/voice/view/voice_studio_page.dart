import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../providers/voice_providers.dart';

const _voiceScripts = [
  '小红帽带着篮子走进了森林',
  '她要去看望生病的奶奶',
  '森林里的小鸟在快乐地歌唱',
];

@RoutePage()
class VoiceStudioPage extends ConsumerStatefulWidget {
  const VoiceStudioPage({super.key});

  @override
  ConsumerState<VoiceStudioPage> createState() => _VoiceStudioPageState();
}

class _VoiceStudioPageState extends ConsumerState<VoiceStudioPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  String _role = 'dad';
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceControllerProvider.notifier).loadVoices();
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceControllerProvider);
    final progress = _audioPath == null ? 0.0 : 1.0;

    return JoyfishScaffold(
      child: ListView(
        padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 34.h),
        children: [
          Row(
            children: [
              Icon(Icons.volume_up_outlined, color: AppTheme.purpleLight, size: 28.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text('录制您的声音', style: Theme.of(context).textTheme.displayMedium),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '让乐鱼用您的声音讲故事',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.mutedInk,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 28.h),
          Row(
            children: [
              Text('录制进度', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              Text(
                _audioPath == null ? '0 / 3' : '3 / 3',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.purpleLight,
                    ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: LinearProgressIndicator(
              minHeight: 10.h,
              value: progress,
              backgroundColor: const Color(0xFFE3EAF0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.purpleLight),
            ),
          ),
          SizedBox(height: 22.h),
          ...List.generate(_voiceScripts.length, (index) {
            final completed = _audioPath != null;
            return Padding(
              padding: EdgeInsets.only(bottom: 18.h),
              child: JoyfishCard(
                border: index == 0 && !completed
                    ? Border.all(color: AppTheme.purpleLight, width: 2.4)
                    : completed && index == _voiceScripts.length - 1
                        ? Border.all(color: AppTheme.purpleLight, width: 2.2)
                        : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? AppTheme.leaf
                            : index == 0
                                ? AppTheme.purple
                                : const Color(0xFFE6EAF0),
                      ),
                      child: completed
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index == 0 ? Colors.white : AppTheme.mutedInk,
                                fontWeight: FontWeight.w700,
                                fontSize: 20.sp,
                              ),
                            ),
                    ),
                    SizedBox(width: 18.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_voiceScripts[index], style: Theme.of(context).textTheme.headlineLarge),
                          if (completed) ...[
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: _togglePreview,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: AppTheme.purpleLight, size: 24.sp),
                                  Text(
                                    _player.playing ? '暂停录音' : '播放录音',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.purpleLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 10.h),
          DropdownButtonFormField<String>(
            key: ValueKey(_role),
            initialValue: _role,
            decoration: const InputDecoration(hintText: '选择音色角色'),
            items: const [
              DropdownMenuItem(value: 'dad', child: Text('爸爸')),
              DropdownMenuItem(value: 'mom', child: Text('妈妈')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _role = value);
            },
          ),
          SizedBox(height: 28.h),
          if (_audioPath == null)
            AppButton(
              text: _isRecording ? '结束录制' : '开始录制',
              isLoading: false,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9900), Color(0xFFFFBA00)],
              ),
              icon: const Icon(Icons.mic_none_rounded, color: Colors.white),
              onPressed: _toggleRecording,
            )
          else
            AppButton(
              text: '完成并上传',
              isLoading: state.isUploading,
              gradient: const LinearGradient(
                colors: [Color(0xFF1ABC7E), Color(0xFF0EA56D)],
              ),
              icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
              onPressed: _uploadVoice,
            ),
          if (state.error != null) ...[
            SizedBox(height: 12.h),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      return;
    }

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先允许麦克风权限')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 32000,
      ),
      path: path,
    );

    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _audioPath = null;
    });
  }

  Future<void> _togglePreview() async {
    final path = _audioPath;
    if (path == null) return;

    if (_player.playing) {
      await _player.pause();
      if (mounted) setState(() {});
      return;
    }

    await _player.setFilePath(path);
    await _player.play();
    if (mounted) setState(() {});
  }

  Future<void> _uploadVoice() async {
    final path = _audioPath;
    if (path == null) return;

    final bytes = await File(path).readAsBytes();
    final transcript = _voiceScripts.join('，');
    final result = await ref.read(voiceControllerProvider.notifier).uploadVoice(
          role: _role,
          displayName: _role == 'dad' ? '爸爸' : '妈妈',
          transcript: transcript,
          audioBase64: base64Encode(bytes),
          mimeType: 'audio/mp4',
        );
    if (result != null && mounted) {
      context.router.popForced();
    }
  }
}

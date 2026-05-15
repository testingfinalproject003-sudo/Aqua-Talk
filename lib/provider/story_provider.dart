import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

class StoryProvider with ChangeNotifier {
  final StoryService _storyService = StoryService();
  final List<StoryModel> _stories = [];
  bool _isLoading = false;
  String? _error;

  List<StoryModel> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> addStory(String path, {bool isVideo = false, String caption = ''}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final file = File(path);
      await _storyService.addStory(caption: caption, image: file, isVideo: isVideo);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStory(String ownerId, String storyId) async {
    try {
      await _storyService.deleteStory(ownerId: ownerId, storyId: storyId);
      _stories.removeWhere((s) => s.storyId == storyId && s.userId == ownerId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> downloadStory(String mediaUrl, {bool isVideo = false}) async {
    return await _storyService.downloadStory(mediaUrl, isVideo: isVideo);
  }

  Future<void> replyToStory({required String storyOwnerId, required String storyId, required String replyText, required String storyImageUrl}) async {
    try {
      await _storyService.replyToStory(storyOwnerId: storyOwnerId, storyId: storyId, replyText: replyText, storyImageUrl: storyImageUrl);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cleanupExpiredStories() async {
    await _storyService.cleanupExpiredStories();
  }

  Stream<List<StoryModel>> get activeStoriesStream => _storyService.activeStoriesStream();
  Stream<List<StoryModel>> get myStoriesStream => _storyService.getMyStories();
  
}
import 'package:flutter/material.dart';

import '../data/avatars_data.dart';
import '../data/game_data.dart';
import '../data/progress_store.dart';

/// Digital India Passport identity — asked once when the player starts their
/// first journey (from the Journey Progression page). Collects the explorer's
/// name and a Boy/Girl avatar, then stamps them into the passport cover.
///
/// Pops with `true` once the identity is saved.
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final TextEditingController _name = TextEditingController();
  String _avatarId = explorerAvatars.first.id;
  bool _nameTouched = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _name.text.trim().isNotEmpty && _avatarId.isNotEmpty;

  void _continue() {
    setState(() => _nameTouched = true);
    if (!_canContinue) return;
    GameData.setIdentity(_name.text, _avatarId);
    ProgressStore.save();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B33),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _IdentityBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBand(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _titleBlock(),
                        const SizedBox(height: 16),
                        _nameField(),
                        const SizedBox(height: 20),
                        _avatarLabel(),
                        const SizedBox(height: 10),
                        _avatarGrid(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                  child: _continueButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.10),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(false),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "DIGITAL INDIA PASSPORT 🛂",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFF22314F), Color(0xFF19253D)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CREATE YOUR PASSPORT",
            style: TextStyle(
              color: Color(0xFFFFE082),
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Every state you explore gets stamped here. First, tell us "
            "who the explorer is — your name and a Boy/Girl avatar.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameField() {
    final error = _nameTouched && _name.text.trim().isEmpty;
    return TextField(
      controller: _name,
      textCapitalization: TextCapitalization.words,
      maxLength: 24,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      cursorColor: const Color(0xFFFFCC66),
      decoration: InputDecoration(
        counterText: "",
        labelText: "EXPLORER NAME",
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
        errorText: error ? "Please enter your name" : null,
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
        prefixIcon: const Icon(Icons.badge_rounded,
            color: Color(0xFFFFD54F), size: 22),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: (error ? const Color(0xFFFF6B6B) : Colors.white)
                .withValues(alpha: error ? 0.8 : 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD54F), width: 1.4),
        ),
      ),
    );
  }

  Widget _avatarLabel() {
    return const Text(
      "CHOOSE YOUR EXPLORER AVATAR",
      style: TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _avatarGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final a in explorerAvatars) _avatarTile(a),
      ],
    );
  }

  Widget _avatarTile(ExplorerAvatar a) {
    final selected = a.id == _avatarId;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _avatarId = a.id),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF9A825).withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFD54F)
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: selected ? 0.95 : 0.12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFFE082)
                      : Colors.white24,
                  width: 2,
                ),
              ),
              child: Text(
                a.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              a.label,
              style: TextStyle(
                color: selected ? const Color(0xFFFFE082) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              a.kind.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continueButton() {
    final ok = _canContinue;
    return Material(
      color: ok ? const Color(0xFFFF9933) : const Color(0xFF2A3550),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _continue,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              ok ? "CREATE MY PASSPORT 🛂" : "ENTER NAME & AVATAR",
              style: TextStyle(
                color: ok ? Colors.white : Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityBackdrop extends StatelessWidget {
  const _IdentityBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9933).withValues(alpha: 0.18),
                    const Color(0xFFFF9933).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16A085).withValues(alpha: 0.16),
                    const Color(0xFF16A085).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
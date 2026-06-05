<?php
session_start();
require_once 'config.php';

if (isset($_SESSION['user'])) {
    header('Location: index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if ($username && $password) {
        $db = getDB();
        $stmt = $db->prepare("SELECT * FROM utilisateurs WHERE username = ?");
        $stmt->execute([$username]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user && password_verify($password, $user['password'])) {
            $_SESSION['user'] = $user['username'];
            $_SESSION['nom'] = $user['nom'];
            $_SESSION['role'] = $user['role'];
            header('Location: index.php');
            exit;
        } else {
            $error = 'Identifiants incorrects.';
        }
    } else {
        $error = 'Veuillez remplir tous les champs.';
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>LOGISTIA — Connexion</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #0f1117; color: #e0e0e0; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .login-box { background: #1a1d27; border-radius: 12px; padding: 40px; width: 380px; border-top: 3px solid #2563eb; }
        h1 { color: #2563eb; font-size: 2rem; letter-spacing: 3px; text-align: center; margin-bottom: 8px; }
        .subtitle { text-align: center; color: #9ca3af; font-size: 0.85rem; margin-bottom: 30px; }
        label { display: block; font-size: 0.85rem; color: #9ca3af; margin-bottom: 6px; }
        input { width: 100%; padding: 10px 14px; background: #0f1117; border: 1px solid #2d3148; border-radius: 6px; color: #e0e0e0; font-size: 0.95rem; margin-bottom: 18px; }
        input:focus { outline: none; border-color: #2563eb; }
        button { width: 100%; padding: 12px; background: #2563eb; border: none; border-radius: 6px; color: white; font-size: 1rem; cursor: pointer; font-weight: bold; letter-spacing: 1px; }
        button:hover { background: #1d4ed8; }
        .error { background: #ef444422; color: #ef4444; padding: 10px; border-radius: 6px; font-size: 0.85rem; margin-bottom: 15px; text-align: center; }
    </style>
</head>
<body>
<div class="login-box">
    <h1>⬡ LOGISTIA</h1>
    <p class="subtitle">Portail de gestion logistique</p>
    <?php if ($error): ?>
    <div class="error"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>
    <form method="POST">
        <label>Identifiant</label>
        <input type="text" name="username" autofocus>
        <label>Mot de passe</label>
        <input type="password" name="password">
        <button type="submit">SE CONNECTER</button>
    </form>
</div>
</body>
</html>

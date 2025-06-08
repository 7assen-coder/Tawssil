import React, { useState } from 'react';
import { Box, Card, CardContent, Typography, TextField, Button, IconButton, InputAdornment, Menu, MenuItem } from '@mui/material';
import EmailIcon from '@mui/icons-material/Email';
import VpnKeyIcon from '@mui/icons-material/VpnKey';
import LanguageIcon from '@mui/icons-material/Language';

const translations = {
  ar: {
    title: 'تسجيل الدخول للوحة الإدارة',
    email: 'البريد الإلكتروني',
    password: 'كلمة المرور',
    login: 'دخول',
    error: 'يرجى إدخال البريد الإلكتروني وكلمة المرور',
    error_admin: 'الدخول مسموح فقط للمسؤولين',
    error_invalid: 'بيانات الدخول غير صحيحة',
    lang: 'العربية',
  },
  fr: {
    title: 'Connexion à l’admin',
    email: 'E-mail',
    password: 'Mot de passe',
    login: 'Connexion',
    error: 'Veuillez saisir l’e-mail et le mot de passe',
    error_admin: 'Seuls les administrateurs peuvent se connecter',
    error_invalid: 'Identifiants invalides',
    lang: 'Français',
  },
};

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [lang, setLang] = useState('fr');
  const [anchorEl, setAnchorEl] = useState(null);
  const [loading, setLoading] = useState(false);

  const t = translations[lang];

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    if (email && password) {
      setLoading(true);
      try {
        const response = await fetch('http://localhost:8000/api/login/', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password })
        });
        const data = await response.json();
        if (data.status === 'success' && data.user && data.user.type_utilisateur === 'Administrateur') {
          localStorage.setItem('token', data.tokens.access);
          localStorage.setItem('refresh', data.tokens.refresh);
          localStorage.setItem('user', JSON.stringify(data.user));
          localStorage.setItem('username', data.user.username);
          localStorage.setItem('adminUser', JSON.stringify({
            username: data.user.username,
            role: data.user.is_superuser ? 'Directeur général' : 'Administrateur'
          }));
          window.location.href = '/';
        } else if (data.status === 'success') {
          setError(t.error_admin);
        } else {
          setError(translations.fr.error_invalid);
        }
      } catch (err) {
        setError(translations.fr.error_invalid);
      } finally {
        setLoading(false);
      }
    } else {
      setError(translations.fr.error);
    }
  };

  const handleLangClick = (event) => {
    setAnchorEl(event.currentTarget);
  };
  const handleLangClose = (lng) => {
    if (lng) setLang(lng);
    setAnchorEl(null);
  };

  return (
    <Box minHeight="100vh" display="flex" alignItems="center" justifyContent="center"
      sx={{
        background: 'linear-gradient(135deg, #1976d2 0%, #42a5f5 100%)',
        direction: lang === 'ar' ? 'rtl' : 'ltr',
      }}
    >
      <Card sx={{ minWidth: 350, maxWidth: 400, p: 2, boxShadow: 6, borderRadius: 4, position: 'relative' }}>
        {/* زر اللغة */}
        <Box position="absolute" top={12} left={lang === 'ar' ? 12 : 'unset'} right={lang === 'ar' ? 'unset' : 12} zIndex={2}>
          <IconButton onClick={handleLangClick} size="small" color="primary">
            <LanguageIcon />
          </IconButton>
          <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={() => handleLangClose()}>
            <MenuItem onClick={() => handleLangClose('ar')}>العربية</MenuItem>
            <MenuItem onClick={() => handleLangClose('fr')}>Français</MenuItem>
          </Menu>
        </Box>
        <CardContent>
          <Box display="flex" flexDirection="column" alignItems="center" mb={2}>
            <Box mb={1}>
              <img src={process.env.PUBLIC_URL + '/Tawssil_logo2.png'} alt="Tawssil Logo" style={{ width: 80, height: 80, objectFit: 'contain', borderRadius: 16, boxShadow: '0 4px 16px rgba(25,118,210,0.12)' }} />
            </Box>
            <Typography variant="h5" fontWeight={700} mb={1}>{t.title}</Typography>
          </Box>
          <form onSubmit={handleLogin} autoComplete="off">
            <TextField
              label={t.email}
              type="email"
              fullWidth
              margin="normal"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <EmailIcon color="primary" />
                  </InputAdornment>
                ),
              }}
            />
            <TextField
              label={t.password}
              type="password"
              fullWidth
              margin="normal"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <VpnKeyIcon color="primary" />
                  </InputAdornment>
                ),
              }}
            />
            {error && <Typography color="error" fontSize={14} mt={1}>{error}</Typography>}
            <Button type="submit" variant="contained" color="primary" fullWidth sx={{ mt: 2, fontWeight: 700, fontSize: 18, py: 1.2, borderRadius: 2 }} disabled={loading}>
              {loading ? '...' : t.login}
            </Button>
          </form>
        </CardContent>
      </Card>
    </Box>
  );
};

export default Login; 
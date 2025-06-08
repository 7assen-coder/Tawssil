import React, { useState, useEffect, useCallback } from 'react';
import { Avatar, Box, Typography, Paper, TextField, Divider, List, ListItem, ListItemAvatar, ListItemText, Badge, IconButton, Modal, CircularProgress, ListItemButton } from '@mui/material';
import SendIcon from '@mui/icons-material/Send';
import DoneAllIcon from '@mui/icons-material/DoneAll';
import DoneIcon from '@mui/icons-material/Done';
import AddCommentIcon from '@mui/icons-material/AddComment';
import './CustomerSupport.css';

const tawssilLogo = process.env.PUBLIC_URL + '/Tawssil_logo.png';

const WelcomeMessage = () => (
  <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: '#1976d2', gap: 2 }}>
    <Avatar src={tawssilLogo} sx={{ width: 90, height: 90, mb: 2, bgcolor: 'transparent' }} variant="rounded" />
    <Typography variant="h5" fontWeight={700}>Bienvenue sur le support</Typography>
    <Typography variant="body1" color="text.secondary">Sélectionnez une conversation pour commencer</Typography>
  </Box>
);

// دالة مساعدة لجلب التوكن من localStorage أو sessionStorage
function getToken() {
  return localStorage.getItem('token') || sessionStorage.getItem('token') || '';
}

// دالة لتجميع الرسائل حسب اليوم
function groupMessagesByDay(messages) {
  const groups = {};
  messages.forEach(msg => {
    if (!msg.date) return;
    const [datePart, timePart] = msg.date.split(' ');
    if (!groups[datePart]) groups[datePart] = [];
    groups[datePart].push({ ...msg, time: timePart });
  });
  return groups;
}

// دالة لتحويل التاريخ إلى نص ودّي
function getDayLabel(datePart) {
  const [day, month, year] = datePart.split('/').map(Number);
  const now = new Date();
  const msgDate = new Date(year, month - 1, day);
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const diff = (today - msgDate) / (1000 * 60 * 60 * 24);
  if (diff === 0) return "Aujourd'hui";
  if (diff === 1) return "Hier";
  return `${datePart}`;
}

// دالة لترتيب المستخدمين حسب النوع
function groupUsersByType(users) {
  const groups = { Client: [], Chauffeur: [], Livreur: [] };
  users.forEach(u => {
    if (groups[u.type_utilisateur]) {
      groups[u.type_utilisateur].push(u);
    }
  });
  return groups;
}

const CustomerSupport = () => {
  const [contacts, setContacts] = useState([]);
  const [selectedContact, setSelectedContact] = useState(null);
  const [messages, setMessages] = useState([]);
  const [message, setMessage] = useState('');
  const [firstUnreadIndex, setFirstUnreadIndex] = useState(null);
  const token = getToken();
  const [openNewChat, setOpenNewChat] = useState(false);
  const [userList, setUserList] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [userListError, setUserListError] = useState('');

  // جلب قائمة المحادثات
  useEffect(() => {
    fetch('http://localhost:8000/api/messaging/conversations/', {
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) {
          setContacts(data);
        } else {
          setContacts([]); // أو يمكنك عرض رسالة خطأ للمستخدم
        }
      })
      .catch(() => setContacts([]));
  }, [token]);

  // جلب رسائل جهة الاتصال المختارة
  useEffect(() => {
    if (selectedContact) {
      fetch(`http://localhost:8000/api/messaging/conversations/${selectedContact.id}/messages/`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      })
        .then(res => res.json())
        .then(data => setMessages(data));
    } else {
      setMessages([]);
    }
  }, [selectedContact, token]);

  // حساب أول رسالة غير مقروءة
  useEffect(() => {
    if (selectedContact && messages.length > 0) {
      const idx = messages.findIndex(msg => !msg.read && !msg.fromMe);
      setFirstUnreadIndex(idx !== -1 ? idx : null);
    } else {
      setFirstUnreadIndex(null);
    }
  }, [messages, selectedContact]);

  // دالة لجلب المستخدمين من الأنواع المطلوبة
  const fetchUserList = useCallback(() => {
    setLoadingUsers(true);
    setUserListError('');
    fetch('http://localhost:8000/api/utilisateurs/clients-drivers/', {
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) {
          setUserList(data);
        } else {
          setUserList([]);
          setUserListError('Impossible de charger les utilisateurs');
        }
        setLoadingUsers(false);
      })
      .catch(() => {
        setUserList([]);
        setUserListError('Impossible de charger les utilisateurs');
        setLoadingUsers(false);
      });
  }, [token]);

  // عند فتح النافذة المنبثقة، جلب المستخدمين
  useEffect(() => {
    if (openNewChat) {
      fetchUserList();
    }
  }, [openNewChat, fetchUserList]);

  const handleSend = async () => {
    if (message.trim() === '' || !selectedContact) return;
    const msgText = message.trim();
    setMessage('');
    try {
      const res = await fetch(`http://localhost:8000/api/messaging/conversations/${selectedContact.id}/send/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        },
        body: JSON.stringify({ contenu: msgText })
      });
      if (res.ok) {
        const data = await res.json();
        setMessages(prev => [...prev, data]);
      } else {
        // في حال فشل الإرسال، يمكن عرض رسالة خطأ أو إعادة الرسالة للمدخل
        setMessage(msgText);
        // يمكنك هنا عرض إشعار خطأ للمستخدم
      }
    } catch (e) {
      setMessage(msgText);
      // يمكنك هنا عرض إشعار خطأ للمستخدم
    }
  };

  const handleSelectContact = (contact) => {
    setSelectedContact(contact);
    // تحديث الرسائل إلى مقروءة في الباكند
    fetch(`http://localhost:8000/api/messaging/conversations/${contact.id}/mark-read/`, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    });
    // تحديث الشارة في الواجهة مباشرة
    setContacts(prev =>
      prev.map(c => c.id === contact.id ? { ...c, unread: 0 } : c)
    );
  };

  const handleSelectNewUser = (user) => {
    setSelectedContact({
      id: user.id_utilisateur,
      username: user.username,
      type_utilisateur: user.type_utilisateur,
      photo_profile: user.photo_profile,
      email: user.email,
      telephone: user.telephone,
      lastMessage: '',
      lastMessageTime: '',
      unread: 0,
    });
    setOpenNewChat(false);
  };

  const grouped = groupMessagesByDay(messages);

  return (
    <Box
      className="messenger-root"
      sx={{
        display: 'flex',
        height: { xs: '90vh', md: '92vh', lg: '95vh' },
        minHeight: 400,
        maxHeight: '98vh',
        width: { xs: '100vw', md: '90vw', lg: '80vw' },
        maxWidth: '1400px',
        margin: 'auto',
        bgcolor: 'linear-gradient(135deg, #fafdff 0%, #e3f0ff 100%)',
        borderRadius: { xs: 0, md: 6 },
        boxShadow: { xs: 2, md: 8 },
        overflow: 'hidden',
        fontFamily: 'Cairo, Roboto, sans-serif',
        transition: '0.3s',
      }}
    >
      {/* الشريط الجانبي */}
      <Paper
        elevation={4}
        className="messenger-sidebar"
        sx={{
          width: { xs: 90, sm: 320, md: 370, lg: 400 },
          minWidth: { xs: 70, sm: 260 },
          maxWidth: { xs: 120, sm: 400 },
          bgcolor: '#fafdff',
          borderRight: '1px solid #e0e0e0',
          display: 'flex',
          flexDirection: 'column',
          position: 'relative',
          boxShadow: { xs: 0, md: 4 },
          zIndex: 2,
        }}
      >
        {/* شريط علوي جانبي */}
        <Box sx={{ p: { xs: 1, sm: 2 }, borderBottom: '1px solid #f0f0f0', bgcolor: '#eaf3fb', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box display="flex" alignItems="center" gap={1}>
            <Avatar src={tawssilLogo} sx={{ width: { xs: 28, sm: 40 }, height: { xs: 28, sm: 40 }, bgcolor: '#fff' }} variant="rounded" />
            <Typography variant="h6" fontWeight={900} color="#1976d2" fontSize={{ xs: 16, sm: 22 }}>Tawssil</Typography>
          </Box>
          <IconButton color="primary" sx={{ bgcolor: '#e3f0ff', p: { xs: 0.5, sm: 1 } }} onClick={() => setOpenNewChat(true)}>
            <AddCommentIcon fontSize="medium" />
          </IconButton>
        </Box>
        {/* البحث */}
        <Box sx={{ p: { xs: 1, sm: 1.5 }, borderBottom: '1px solid #f0f0f0', bgcolor: '#fafdff' }}>
          <TextField size="small" fullWidth placeholder="Rechercher..." variant="outlined" sx={{ bgcolor: '#f7faff', borderRadius: 2, fontSize: { xs: 12, sm: 16 } }} />
        </Box>
        {/* قائمة المحادثات */}
        <List sx={{ flex: 1, overflowY: 'auto', p: 0, bgcolor: '#fafdff' }}>
          {Array.isArray(contacts) && contacts.map(contact => (
            <React.Fragment key={contact.id}>
              <ListItem
                button
                alignItems="flex-start"
                selected={selectedContact && selectedContact.id === contact.id}
                onClick={() => handleSelectContact(contact)}
                sx={{
                  borderRadius: 3,
                  mb: 0.5,
                  bgcolor: selectedContact && selectedContact.id === contact.id ? '#e3f0ff' : 'inherit',
                  transition: '0.2s',
                  boxShadow: selectedContact && selectedContact.id === contact.id ? 3 : 0,
                  p: { xs: 0.7, sm: 1.3 },
                  minHeight: { xs: 65, sm: 80 },
                  gap: 1.2,
                }}
              >
                <ListItemAvatar sx={{ minWidth: { xs: 44, sm: 56 } }}>
                  <Badge color={contact.isOnline ? 'success' : 'default'} variant="dot" overlap="circular" anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
                    <Avatar src={contact.photo_profile} alt={contact.username} sx={{ width: { xs: 44, sm: 56 }, height: { xs: 44, sm: 56 }, boxShadow: 1 }} />
                  </Badge>
                </ListItemAvatar>
                <Box sx={{ flex: 1, minWidth: 0, ml: 0.5 }}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <Typography fontWeight={900} fontSize={{ xs: 15, sm: 18 }} sx={{ lineHeight: 1.1 }}>{contact.username}</Typography>
                    <Typography variant="caption" color="text.secondary" fontSize={{ xs: 11, sm: 14 }}>({contact.type_utilisateur})</Typography>
                  </Box>
                  <Box display="flex" alignItems="center" justifyContent="space-between" mt={0.5}>
                    <Typography variant="body2" color="text.secondary" noWrap sx={{ maxWidth: { xs: 120, sm: 180 }, fontSize: { xs: 12, sm: 15 }, opacity: 0.8 }}>{contact.lastMessage}</Typography>
                    <Typography variant="caption" color="text.secondary" fontSize={{ xs: 11, sm: 13 }} sx={{ ml: 1 }}>{contact.lastMessageTime}</Typography>
                  </Box>
                </Box>
                {contact.unread > 0 && <Badge color="primary" badgeContent={contact.unread} sx={{ ml: 1 }} />}
              </ListItem>
              <Divider variant="inset" component="li" sx={{ ml: { xs: 5, sm: 7 }, borderColor: '#f0f0f0' }} />
            </React.Fragment>
          ))}
        </List>
      </Paper>
      {/* نافذة الدردشة */}
      <Box
        className="messenger-chat"
        sx={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          bgcolor: 'linear-gradient(135deg, #fafdff 0%, #e3f0ff 100%)',
          minWidth: 0,
        }}
      >
        {/* شريط أعلى الدردشة */}
        {selectedContact ? (
          <Box sx={{ p: { xs: 1.5, sm: 3 }, borderBottom: '1px solid #e0e0e0', display: 'flex', alignItems: 'center', gap: { xs: 1, sm: 3 }, bgcolor: '#fff', minHeight: { xs: 60, sm: 90 } }}>
            <Avatar src={selectedContact.photo_profile} alt={selectedContact.username} sx={{ width: { xs: 44, sm: 70 }, height: { xs: 44, sm: 70 }, boxShadow: 2 }} />
            <Box>
              <Typography fontWeight={900} fontSize={{ xs: 16, sm: 24 }}>{selectedContact.username}</Typography>
              <Typography variant="body2" color="text.secondary" fontSize={{ xs: 12, sm: 16 }}>{selectedContact.type_utilisateur} {selectedContact.isOnline ? <span style={{ color: '#43a047', fontWeight: 700 }}>• en ligne</span> : <span style={{ color: '#aaa' }}>• hors ligne</span>}</Typography>
            </Box>
          </Box>
        ) : null}
        {/* الرسائل أو رسالة ترحيبية */}
        <Box sx={{ flex: 1, p: { xs: 1.5, sm: 4 }, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 2, bgcolor: 'transparent', minHeight: 0 }}>
          {selectedContact ? (
            Object.entries(grouped).map(([datePart, msgs]) => (
              <React.Fragment key={datePart}>
                <Box sx={{ textAlign: 'center', my: 2 }}>
                  <Typography variant="caption" sx={{ bgcolor: '#eee', px: 2, py: 0.5, borderRadius: 2, fontWeight: 700 }}>
                    {getDayLabel(datePart)}
                  </Typography>
                </Box>
                {msgs.map((msg, idx) => (
                  <React.Fragment key={idx}>
                    {firstUnreadIndex !== null && idx === firstUnreadIndex && (
                      <Box sx={{ textAlign: 'center', my: 1 }}>
                        <Typography variant="caption" sx={{ bgcolor: '#1976d2', color: '#fff', px: 2, py: 0.5, borderRadius: 2, fontWeight: 700 }}>
                          Nouveaux messages
                        </Typography>
                      </Box>
                    )}
                    <Box sx={{ display: 'flex', flexDirection: msg.fromMe ? 'row-reverse' : 'row', alignItems: 'flex-end', gap: 1 }}>
                      <Avatar src={selectedContact.photo_profile} alt={selectedContact.username} sx={{ width: { xs: 28, sm: 40 }, height: { xs: 28, sm: 40 }, visibility: msg.fromMe ? 'hidden' : 'visible', boxShadow: 1 }} />
                      <Box sx={{
                        maxWidth: { xs: '80%', sm: '65%' },
                        bgcolor: msg.fromMe ? '#1976d2' : '#fff',
                        color: msg.fromMe ? '#fff' : '#222',
                        p: { xs: 1.7, sm: 2.2 },
                        borderRadius: msg.fromMe ? { xs: '16px 6px 16px 16px', sm: '22px 6px 22px 22px' } : { xs: '6px 16px 16px 16px', sm: '6px 22px 22px 22px' },
                        boxShadow: 2,
                        position: 'relative',
                        fontSize: { xs: 15, sm: 18 },
                        transition: '0.2s',
                        wordBreak: 'break-word',
                        border: msg.fromMe ? 'none' : '1.5px solid #e0e0e0',
                        opacity: 1,
                      }}>
                        <Typography variant="body1" sx={{ fontWeight: 500, color: msg.fromMe ? '#fff' : '#222', fontSize: { xs: 15, sm: 18 } }}>{msg.text}</Typography>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 0.7, mt: 0.7 }}>
                          <Typography variant="caption" sx={{ color: msg.fromMe ? '#fff' : '#555', fontWeight: 500, fontSize: { xs: 12, sm: 14 }, letterSpacing: 0.5 }}>{msg.time}</Typography>
                          {msg.fromMe && (msg.read ? <DoneAllIcon fontSize="small" sx={{ color: '#b2ff59', ml: 0.5 }} /> : <DoneIcon fontSize="small" sx={{ color: '#fff', ml: 0.5 }} />)}
                        </Box>
                      </Box>
                    </Box>
                  </React.Fragment>
                ))}
              </React.Fragment>
            ))
          ) : (
            <WelcomeMessage />
          )}
        </Box>
        {/* شريط إدخال الرسالة */}
        <Divider />
        <Box sx={{ p: { xs: 1, sm: 2.5 }, display: 'flex', alignItems: 'center', gap: { xs: 1, sm: 2 }, bgcolor: '#fff', minHeight: { xs: 50, sm: 80 } }}>
          <TextField
            fullWidth
            placeholder="Écrire un message..."
            value={message}
            onChange={e => setMessage(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') handleSend(); }}
            size="medium"
            sx={{ bgcolor: '#f7faff', borderRadius: 3, fontSize: { xs: 14, sm: 18 }, p: { xs: 0.5, sm: 1.5 } }}
            disabled={!selectedContact}
          />
          <IconButton
            color="primary"
            onClick={handleSend}
            sx={{
              bgcolor: '#1976d2',
              borderRadius: 2,
              color: '#fff',
              transition: '0.2s',
              '&:hover': { bgcolor: '#1565c0' },
              boxShadow: 2,
              p: { xs: 0.7, sm: 1.5 },
              fontSize: { xs: 18, sm: 24 },
            }}
            disabled={!selectedContact || message.trim() === ''}
          >
            <SendIcon fontSize="large" />
          </IconButton>
        </Box>
      </Box>
      {/* نافذة منبثقة لاختيار مستخدم جديد */}
      <Modal open={openNewChat} onClose={() => setOpenNewChat(false)}>
        <Box sx={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: 370, maxHeight: 500, bgcolor: '#fff', borderRadius: 4, boxShadow: 24, p: 3, outline: 'none', display: 'flex', flexDirection: 'column', gap: 2 }}>
          <Typography variant="h6" fontWeight={900} color="#1976d2" mb={1} textAlign="center">Démarrer une nouvelle discussion</Typography>
          {loadingUsers ? (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight={120}><CircularProgress /></Box>
          ) : userListError ? (
            <Typography color="error" textAlign="center">Impossible de charger les utilisateurs</Typography>
          ) : (
            <List sx={{ maxHeight: 340, overflowY: 'auto', p: 0 }}>
              {(() => {
                const grouped = groupUsersByType(userList);
                const sections = [
                  { label: 'Clients', key: 'Client' },
                  { label: 'Chauffeurs', key: 'Chauffeur' },
                  { label: 'Livreurs', key: 'Livreur' },
                ];
                return sections.map(section =>
                  grouped[section.key].length > 0 ? (
                    <React.Fragment key={section.key}>
                      <Typography variant="subtitle2" fontWeight={700} color="#1976d2" sx={{ mt: 1, mb: 0.5, ml: 1 }}>{section.label}</Typography>
                      {grouped[section.key].map(user => (
                        <ListItemButton key={user.id_utilisateur} onClick={() => handleSelectNewUser(user)}>
                          <ListItemAvatar>
                            <Avatar src={user.photo_profile} alt={user.username} />
                          </ListItemAvatar>
                          <ListItemText
                            primary={<Typography fontWeight={700} fontSize={16}>{user.username}</Typography>}
                            secondary={<Typography variant="body2" color="text.secondary">{user.email}</Typography>}
                          />
                        </ListItemButton>
                      ))}
                    </React.Fragment>
                  ) : null
                );
              })()}
              {userList.length === 0 && <Typography textAlign="center" color="text.secondary">Aucun utilisateur disponible</Typography>}
            </List>
          )}
        </Box>
      </Modal>
    </Box>
  );
};

export default CustomerSupport; 
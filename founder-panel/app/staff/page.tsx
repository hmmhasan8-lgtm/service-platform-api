'use client';

import React, { useState } from 'react';
import {
  CheckCircle,
  XCircle,
  Clock,
  UserCheck,
  Shield,
  FileCheck,
  AlertCircle,
  Eye,
  Lock,
  Search,
  Check,
  ShieldAlert,
  AlertTriangle,
  FileSearch,
  Scissors,
  MessageSquareWarning,
} from 'lucide-react';

export interface PendingPostItem {
  id: string;
  title: string;
  entity_key: string;
  country_code: string;
  user_phone: string;
  approx_location: string;
  submitted_at: string;
  dynamic_data: Record<string, any>;
  has_private_data: boolean;
  status: 'pending' | 'approved' | 'rejected';
  // Officer Verification & Contact Leak Flagging
  is_flagged?: boolean;
  flag_reasons?: string[];
  flagged_snippets?: string[];
  officer_note?: string;
}

export default function StaffModerationPage() {
  const [activeTab, setActiveTab] = useState<'nid_queue' | 'flagged' | 'queue' | 'kyc' | 'history'>('nid_queue');
  const [searchQuery, setSearchQuery] = useState('');
  const [editingPostForSanitize, setEditingPostForSanitize] = useState<PendingPostItem | null>(null);
  const [sanitizedTitle, setSanitizedTitle] = useState('');
  const [officerNote, setOfficerNote] = useState('');

  // MODULE 1: NID + Face Verification Queue
  const [nidVerifications, setNidVerifications] = useState([
    {
      id: 'ver_1',
      user_id: 'usr_8812',
      user_name: 'আব্দুল করিম (এসি টেকনিশিয়ান)',
      phone: '+8801711223344',
      nid_number: '19942692019000456',
      nid_front_image_url: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600&auto=format&fit=crop&q=80',
      nid_back_image_url: 'https://images.unsplash.com/photo-1568992687947-868a62a9f521?w=600&auto=format&fit=crop&q=80',
      selfie_image_url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80',
      submitted_at: '১০ মিনিট আগে',
      status: 'pending',
    },
    {
      id: 'ver_2',
      user_id: 'usr_9921',
      user_name: 'রফিকুল ইসলাম (প্রাইভেট ড্রাইভার)',
      phone: '+8801822334455',
      nid_number: '19892692019000789',
      nid_front_image_url: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600&auto=format&fit=crop&q=80',
      nid_back_image_url: 'https://images.unsplash.com/photo-1568992687947-868a62a9f521?w=600&auto=format&fit=crop&q=80',
      selfie_image_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&auto=format&fit=crop&q=80',
      submitted_at: '২৫ মিনিট আগে',
      status: 'pending',
    },
  ]);

  const [posts, setPosts] = useState<PendingPostItem[]>([
    {
      id: 'post_201',
      title: 'Toyota Premio 2017 - Call 0,1,2,3,1,3,3,4,5,1,1 for direct rental',
      entity_key: 'vehicles',
      country_code: 'BD',
      user_phone: '+8801911998877',
      approx_location: 'মিরপুর ১০, ঢাকা',
      submitted_at: '৩ মিনিট আগে',
      dynamic_data: {
        fuel_type: 'octane',
        security_deposit: 10000,
        hourly_rate: 600,
      },
      has_private_data: true,
      status: 'pending',
      is_flagged: true,
      flag_reasons: [
        'কমা/চিহ্ন দিয়ে লুকানো ফোন নম্বর সনাক্ত (0123***11)',
        'যোগাযোগের কি-ওয়ার্ড (call) সহ ফোন নম্বর সনাক্ত',
      ],
      flagged_snippets: ['0,1,2,3,1,3,3,4,5,1,1'],
    },
    {
      id: 'post_202',
      title: 'Executive AC Service - Contact at booking.service@gmail.com',
      entity_key: 'services',
      country_code: 'BD',
      user_phone: '+8801822334455',
      approx_location: 'ধানমন্ডি, ঢাকা',
      submitted_at: '৭ মিনিট আগে',
      dynamic_data: {
        service_category: 'ac_repair',
        warranty_days: 30,
      },
      has_private_data: true,
      status: 'pending',
      is_flagged: true,
      flag_reasons: [
        'ইমেইল ঠিকানা সনাক্ত হয়েছে (booking.service@gmail.com)',
      ],
      flagged_snippets: ['booking.service@gmail.com'],
    },
    {
      id: 'post_203',
      title: 'Commercial Truck Driver - বাসা নং ১২, রোড নং ৪, সেক্টর ৭',
      entity_key: 'drivers',
      country_code: 'BD',
      user_phone: '+8801755443322',
      approx_location: 'উত্তরা, ঢাকা',
      submitted_at: '১৫ মিনিট আগে',
      dynamic_data: {
        experience_years: 8,
      },
      has_private_data: true,
      status: 'pending',
      is_flagged: true,
      flag_reasons: [
        'সুনির্দিষ্ট বাড়ি ও রোড নম্বর সনাক্ত (Exact physical address leak)',
      ],
      flagged_snippets: ['বাসা নং ১২, রোড নং ৪'],
    },
    {
      id: 'post_101',
      title: 'Toyota Axio 2018 White - Personal Condition',
      entity_key: 'vehicles',
      country_code: 'BD',
      user_phone: '+8801711223344',
      approx_location: 'উত্তরা সেক্টর ৭, ঢাকা',
      submitted_at: '২৫ মিনিট আগে',
      dynamic_data: {
        fuel_type: 'cng',
        security_deposit: 5000,
        hourly_rate: 450,
      },
      has_private_data: true,
      status: 'pending',
      is_flagged: false,
    },
  ]);

  const [kycRequests, setKycRequests] = useState([
    {
      id: 'kyc_1',
      user_id: 'usr_8812',
      user_name: 'Md. Tanvir Ahmed',
      country_code: 'BD',
      doc_type: 'Bangladesh National ID (NID)',
      doc_number: '19922692019000123',
      submitted_at: 'Today, 11:20 AM',
      status: 'pending',
    },
    {
      id: 'kyc_2',
      user_id: 'usr_9931',
      user_name: 'Rahul Sharma',
      country_code: 'IN',
      doc_type: 'Indian Aadhaar Card',
      doc_number: '4829-1928-9102',
      submitted_at: 'Today, 09:15 AM',
      status: 'pending',
    },
  ]);

  const handleModeratePost = (postId: string, newStatus: 'approved' | 'rejected', note?: string) => {
    setPosts((prev) =>
      prev.map((p) => {
        if (p.id === postId) {
          return {
            ...p,
            status: newStatus,
            officer_note: note || (newStatus === 'approved' ? 'Verified by Staff Officer' : 'Rejected for policy violation'),
          };
        }
        return p;
      })
    );
  };

  const handleSanitizeAndApprove = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingPostForSanitize) return;

    setPosts((prev) =>
      prev.map((p) => {
        if (p.id === editingPostForSanitize.id) {
          return {
            ...p,
            title: sanitizedTitle.trim() || p.title,
            status: 'approved',
            is_flagged: false,
            officer_note: officerNote || 'Sanitized phone/email and approved by Officer',
          };
        }
        return p;
      })
    );

    setEditingPostForSanitize(null);
    setSanitizedTitle('');
    setOfficerNote('');
  };

  const handleModerateKyc = (kycId: string, newStatus: 'approved' | 'rejected') => {
    setKycRequests((prev) =>
      prev.map((k) => {
        if (k.id === kycId) {
          return { ...k, status: newStatus };
        }
        return k;
      })
    );
  };

  const flaggedPosts = posts.filter((p) => p.is_flagged && p.status === 'pending');
  const regularPendingPosts = posts.filter((p) => !p.is_flagged && p.status === 'pending');
  const resolvedPosts = posts.filter((p) => p.status !== 'pending');

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 flex flex-col font-sans">
      {/* Header */}
      <header className="bg-slate-900 text-white px-6 py-4 flex items-center justify-between border-b border-slate-800 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-600 text-white rounded-lg">
            <Shield className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-base tracking-wide">STAFF MODERATION & TRUST DESK</span>
              <span className="text-[10px] bg-rose-500/20 text-rose-300 border border-rose-500/40 px-2 py-0.5 rounded-full font-bold">
                LEAK PREVENTION LAYER 2
              </span>
            </div>
            <span className="text-xs text-slate-400">
              Officer Verification Desk: Phone, Email, & Address Leak Prevention
            </span>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="text-right">
            <div className="text-xs font-bold text-slate-200">Staff Officer: Fahim Reza</div>
            <div className="text-[10px] text-emerald-400 font-mono">Trust & Safety Desk (Active)</div>
          </div>
        </div>
      </header>

      {/* Tabs */}
      <div className="bg-white border-b border-slate-200 px-6 flex gap-2 overflow-x-auto">
        {/* MODULE 1: NID + FACE VERIFICATION QUEUE */}
        <button
          onClick={() => setActiveTab('nid_queue')}
          className={`py-3.5 px-4 text-xs font-bold flex items-center gap-2 border-b-2 transition whitespace-nowrap ${
            activeTab === 'nid_queue'
              ? 'border-indigo-600 text-indigo-700 bg-indigo-50/50'
              : 'border-transparent text-slate-600 hover:text-slate-900'
          }`}
        >
          <Shield className="w-4 h-4 text-indigo-600" />
          <span>NID + ফেস ভেরিফিকেশন কিউ (MODULE 1)</span>
          <span className="px-2 py-0.5 rounded-full bg-indigo-600 text-white text-[10px] font-extrabold">
            {nidVerifications.filter((v) => v.status === 'pending').length} Pending
          </span>
        </button>

        {/* PRIORITY TAB: FLAGGED LEAK VERIFICATION */}
        <button
          onClick={() => setActiveTab('flagged')}
          className={`py-3.5 px-4 text-xs font-bold flex items-center gap-2 border-b-2 transition whitespace-nowrap ${
            activeTab === 'flagged'
              ? 'border-rose-600 text-rose-700 bg-rose-50/50'
              : 'border-transparent text-slate-600 hover:text-slate-900'
          }`}
        >
          <ShieldAlert className="w-4 h-4 text-rose-600" />
          <span>সন্দেহজনক কন্টাক্ট ভেরিফিকেশন (Flagged Review)</span>
          <span className="px-2 py-0.5 rounded-full bg-rose-600 text-white text-[10px] font-extrabold animate-pulse">
            {flaggedPosts.length} Alert
          </span>
        </button>

        <button
          onClick={() => setActiveTab('queue')}
          className={`py-3.5 px-4 text-xs font-bold flex items-center gap-2 border-b-2 transition whitespace-nowrap ${
            activeTab === 'queue'
              ? 'border-emerald-600 text-emerald-700 bg-emerald-50/50'
              : 'border-transparent text-slate-600 hover:text-slate-900'
          }`}
        >
          <Clock className="w-4 h-4" />
          <span>সাধারণ পেন্ডিং কিউ (Regular Queue)</span>
          <span className="px-1.5 py-0.5 rounded-full bg-amber-500 text-white text-[10px] font-bold">
            {regularPendingPosts.length}
          </span>
        </button>

        <button
          onClick={() => setActiveTab('kyc')}
          className={`py-3.5 px-4 text-xs font-bold flex items-center gap-2 border-b-2 transition whitespace-nowrap ${
            activeTab === 'kyc'
              ? 'border-emerald-600 text-emerald-700 bg-emerald-50/50'
              : 'border-transparent text-slate-600 hover:text-slate-900'
          }`}
        >
          <UserCheck className="w-4 h-4" />
          <span>KYC Verifications</span>
          <span className="px-1.5 py-0.5 rounded-full bg-blue-600 text-white text-[10px] font-bold">
            {kycRequests.filter((k) => k.status === 'pending').length}
          </span>
        </button>

        <button
          onClick={() => setActiveTab('history')}
          className={`py-3.5 px-4 text-xs font-bold flex items-center gap-2 border-b-2 transition whitespace-nowrap ${
            activeTab === 'history'
              ? 'border-emerald-600 text-emerald-700 bg-emerald-50/50'
              : 'border-transparent text-slate-600 hover:text-slate-900'
          }`}
        >
          <FileCheck className="w-4 h-4" />
          <span>Moderation History ({resolvedPosts.length})</span>
        </button>
      </div>

      <main className="p-6 flex-1 max-w-6xl mx-auto w-full">
        {/* ================================================================= */}
        {/* TAB 0: MODULE 1: NID + FACE VERIFICATION QUEUE                    */}
        {/* ================================================================= */}
        {activeTab === 'nid_queue' && (
          <div className="space-y-5">
            <div className="bg-indigo-50 border border-indigo-200 p-4 rounded-2xl flex items-start gap-3">
              <Shield className="w-6 h-6 text-indigo-600 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-bold text-sm text-indigo-950">
                  প্রোভাইডার NID ও ফেস ভেরিফিকেশন ডেস্ক (MODULE 1: Trust & Safety)
                </h3>
                <p className="text-xs text-indigo-800 mt-1 leading-relaxed">
                  যেসব সার্ভিস প্রোভাইডার তাদের জাতীয় পরিচয়পত্র ও সেলফি আপলোড করেছেন, তাদের তথ্য যাচাই করে অনুমোদন দিন। অনুমোদন পাওয়ার পরই প্রোভাইডাররা কাস্টমারদের সরাসরি পোস্ট দেখতে পারবেন ও কাজ পেতে পারবেন।
                </p>
              </div>
            </div>

            <div className="space-y-4">
              {nidVerifications.map((item) => (
                <div key={item.id} className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-4">
                  <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-slate-100">
                    <div>
                      <div className="flex items-center gap-2">
                        <h4 className="font-bold text-sm text-slate-900">{item.user_name}</h4>
                        <span className="font-mono text-xs text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
                          NID: {item.nid_number}
                        </span>
                        <span className="text-xs text-slate-400">• {item.submitted_at}</span>
                      </div>
                      <p className="text-xs text-slate-500 mt-0.5">
                        মোবাইল: <span className="font-mono text-slate-800">{item.phone}</span>
                      </p>
                    </div>

                    <div className="flex items-center gap-2">
                      {item.status === 'pending' ? (
                        <>
                          <button
                            onClick={() => {
                              setNidVerifications((prev) =>
                                prev.map((v) => (v.id === item.id ? { ...v, status: 'rejected' } : v))
                              );
                            }}
                            className="px-3.5 py-2 bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold rounded-xl text-xs flex items-center gap-1.5 transition"
                          >
                            <XCircle className="w-4 h-4" />
                            <span>বাতিল (Reject)</span>
                          </button>
                          <button
                            onClick={() => {
                              setNidVerifications((prev) =>
                                prev.map((v) => (v.id === item.id ? { ...v, status: 'verified' } : v))
                              );
                            }}
                            className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition"
                          >
                            <CheckCircle className="w-4 h-4" />
                            <span>অনুমোদন দিন (Approve & Verify)</span>
                          </button>
                        </>
                      ) : (
                        <span
                          className={`px-3 py-1 rounded-full text-xs font-bold uppercase ${
                            item.status === 'verified'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-rose-100 text-rose-800'
                          }`}
                        >
                          {item.status === 'verified' ? 'ভেরিফায়েড ✅' : 'প্রত্যাখ্যাত ❌'}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Photos Grid: NID Front, NID Back, Live Selfie */}
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div className="border border-slate-200 rounded-xl p-2 bg-slate-50 text-center space-y-1">
                      <span className="text-[10px] font-bold text-slate-500 block">১. এনআইডি ফ্রন্ট সাইড</span>
                      <div className="h-28 rounded-lg overflow-hidden bg-slate-200">
                        <img src={item.nid_front_image_url} alt="NID Front" className="w-full h-full object-cover" />
                      </div>
                    </div>
                    <div className="border border-slate-200 rounded-xl p-2 bg-slate-50 text-center space-y-1">
                      <span className="text-[10px] font-bold text-slate-500 block">২. এনআইডি ব্যাক সাইড</span>
                      <div className="h-28 rounded-lg overflow-hidden bg-slate-200">
                        <img src={item.nid_back_image_url} alt="NID Back" className="w-full h-full object-cover" />
                      </div>
                    </div>
                    <div className="border border-slate-200 rounded-xl p-2 bg-slate-50 text-center space-y-1">
                      <span className="text-[10px] font-bold text-slate-500 block">৩. ভেরিফিকেশন সেলফি</span>
                      <div className="h-28 rounded-lg overflow-hidden bg-slate-200">
                        <img src={item.selfie_image_url} alt="Live Selfie" className="w-full h-full object-cover" />
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ================================================================= */}
        {/* TAB 1: FLAGGED LEAK VERIFICATION (THE CORE USER REQUIREMENT)       */}
        {/* ================================================================= */}
        {activeTab === 'flagged' && (
          <div className="space-y-5">
            <div className="bg-rose-50 border border-rose-200 p-4 rounded-2xl flex items-start gap-3">
              <ShieldAlert className="w-6 h-6 text-rose-600 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-bold text-sm text-rose-950">
                  কর্মকর্তা কর্তৃক কন্টাক্ট ইনফরমেশন ভেরিফিকেশন ডেস্ক (Layer 2 Protection)
                </h3>
                <p className="text-xs text-rose-800 mt-1 leading-relaxed">
                  যদি কোনো ইউজার কমা বা চিহ্ন দিয়ে বিভক্ত ফোন নম্বর (যেমন: <code>0,1,2,3,1,3,3,4,5,1,1</code>), ইমেইল ঠিকানা, অথবা পূর্ণ বাসা/রোড নম্বর দিয়ে প্ল্যাটফর্মের আনলক ফি ফাঁকি দেওয়ার চেষ্টা করে, তা এই কিউতে জমা হয়। কর্মকর্তা যাচাই করে পোস্ট <strong>রিজেক্ট</strong> করবেন অথবা তথ্য <strong>স্যানিটাইজ (মুছে ফেলে)</strong> অনুমোদন করবেন।
                </p>
              </div>
            </div>

            {flaggedPosts.length === 0 ? (
              <div className="bg-white p-12 rounded-2xl border border-slate-200 text-center">
                <CheckCircle className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
                <h3 className="text-base font-bold text-slate-800">কোনো ফ্ল্যাগড পোস্ট নেই!</h3>
                <p className="text-xs text-slate-500 mt-1">সব পোস্ট পরিষ্কার এবং কোনো কন্টাক্ট লিকের চেষ্টা সনাক্ত হয়নি।</p>
              </div>
            ) : (
              <div className="space-y-4">
                {flaggedPosts.map((post) => (
                  <div
                    key={post.id}
                    className="bg-white rounded-2xl border-2 border-rose-300 shadow-sm p-5 space-y-4"
                  >
                    <div className="flex flex-wrap items-start justify-between gap-3">
                      <div>
                        <div className="flex items-center gap-2 mb-1.5">
                          <span className="px-2 py-0.5 text-[10px] font-extrabold rounded bg-rose-100 text-rose-800 border border-rose-300">
                            🚨 SUSPICIOUS LEAK DETECTED
                          </span>
                          <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-slate-100 text-slate-700 uppercase">
                            {post.entity_key}
                          </span>
                          <span className="text-xs text-slate-400">{post.submitted_at}</span>
                        </div>
                        <h3 className="text-base font-bold text-slate-900 bg-amber-50 p-2 rounded-lg border border-amber-200 font-mono text-sm">
                          {post.title}
                        </h3>
                        <p className="text-xs text-slate-500 mt-1">
                          অবস্থান: <strong>{post.approx_location}</strong> • পোস্টারের ফোন: <span className="font-mono text-indigo-600">{post.user_phone}</span>
                        </p>
                      </div>

                      {/* OFFICER DECISION BUTTONS */}
                      <div className="flex flex-wrap items-center gap-2">
                        {/* SANITIZE & APPROVE BUTTON */}
                        <button
                          onClick={() => {
                            setEditingPostForSanitize(post);
                            // Pre-clean title by removing the flagged snippet
                            let clean = post.title;
                            (post.flagged_snippets || []).forEach((snip) => {
                              clean = clean.replace(snip, '').replace(/call|contact|email|at/gi, '').trim();
                            });
                            setSanitizedTitle(clean);
                            setOfficerNote('Removed direct contact leak and approved');
                          }}
                          className="px-3.5 py-2 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold rounded-xl text-xs flex items-center gap-1.5 border border-indigo-200 transition"
                          title="মুছে ফেলে অনুমোদন করুন"
                        >
                          <Scissors className="w-4 h-4 text-indigo-600" />
                          স্যানিটাইজ ও অনুমোদন (Clean & Approve)
                        </button>

                        {/* REJECT BUTTON */}
                        <button
                          onClick={() => handleModeratePost(post.id, 'rejected', 'Rejected for deliberate contact leakage attempt')}
                          className="px-3.5 py-2 bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold rounded-xl text-xs flex items-center gap-1.5 border border-rose-200 transition"
                        >
                          <XCircle className="w-4 h-4 text-rose-600" />
                          রিজেক্ট করুন (Reject)
                        </button>

                        {/* DIRECT APPROVE */}
                        <button
                          onClick={() => handleModeratePost(post.id, 'approved', 'Manually verified as safe by Officer')}
                          className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition"
                        >
                          <CheckCircle className="w-4 h-4" />
                          বৈধ ঘোষণা করুন (Approve)
                        </button>
                      </div>
                    </div>

                    {/* DETECTED LEAK REASONS BOX */}
                    <div className="p-3 bg-rose-50/70 border border-rose-200 rounded-xl space-y-1.5 text-xs">
                      <span className="font-bold text-rose-950 flex items-center gap-1.5">
                        <AlertTriangle className="w-3.5 h-3.5 text-rose-600" />
                        সিস্টেম কর্তৃক সনাক্তকৃত কারণসমূহ:
                      </span>
                      <ul className="list-disc list-inside space-y-1 text-rose-900 font-medium">
                        {(post.flag_reasons || []).map((reason, i) => (
                          <li key={i}>{reason}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ================================================================= */}
        {/* TAB 2: REGULAR QUEUE                                              */}
        {/* ================================================================= */}
        {activeTab === 'queue' && (
          <div className="space-y-4">
            <h2 className="text-xl font-bold text-slate-800">Regular Moderation Queue</h2>
            {regularPendingPosts.length === 0 ? (
              <div className="bg-white p-8 rounded-2xl border border-slate-200 text-center">
                <CheckCircle className="w-10 h-10 text-emerald-500 mx-auto mb-2" />
                <p className="text-xs text-slate-500">No regular posts pending review.</p>
              </div>
            ) : (
              <div className="space-y-3">
                {regularPendingPosts.map((post) => (
                  <div key={post.id} className="bg-white p-5 rounded-2xl border border-slate-200 flex items-center justify-between">
                    <div>
                      <h4 className="font-bold text-sm text-slate-900">{post.title}</h4>
                      <p className="text-xs text-slate-500">{post.approx_location} • {post.entity_key}</p>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleModeratePost(post.id, 'rejected')}
                        className="px-3 py-1.5 bg-rose-50 text-rose-700 rounded-lg text-xs font-bold"
                      >
                        Reject
                      </button>
                      <button
                        onClick={() => handleModeratePost(post.id, 'approved')}
                        className="px-4 py-1.5 bg-emerald-600 text-white rounded-lg text-xs font-bold"
                      >
                        Approve
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ================================================================= */}
        {/* TAB 3: KYC                                                        */}
        {/* ================================================================= */}
        {activeTab === 'kyc' && (
          <div className="space-y-4">
            <h2 className="text-xl font-bold text-slate-800">User Identity Verification (KYC)</h2>
            <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 font-bold uppercase text-slate-600">
                  <tr>
                    <th className="p-4">Name</th>
                    <th className="p-4">Region</th>
                    <th className="p-4">Document</th>
                    <th className="p-4">ID Number</th>
                    <th className="p-4 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {kycRequests.map((k) => (
                    <tr key={k.id}>
                      <td className="p-4 font-bold text-slate-900">{k.user_name}</td>
                      <td className="p-4 font-bold">{k.country_code}</td>
                      <td className="p-4 text-slate-600">{k.doc_type}</td>
                      <td className="p-4 font-mono font-bold text-indigo-600">{k.doc_number}</td>
                      <td className="p-4 text-right">
                        {k.status === 'pending' ? (
                          <button
                            onClick={() => handleModerateKyc(k.id, 'approved')}
                            className="px-3 py-1 bg-emerald-600 text-white rounded-lg font-bold"
                          >
                            Verify
                          </button>
                        ) : (
                          <span className="text-emerald-700 font-bold uppercase">{k.status}</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ================================================================= */}
        {/* TAB 4: HISTORY                                                    */}
        {/* ================================================================= */}
        {activeTab === 'history' && (
          <div className="space-y-3">
            <h2 className="text-xl font-bold text-slate-800">Moderation History</h2>
            {resolvedPosts.map((p) => (
              <div key={p.id} className="bg-white p-4 rounded-xl border border-slate-200 flex items-center justify-between">
                <div>
                  <h4 className="font-bold text-sm text-slate-800">{p.title}</h4>
                  <span className="text-xs text-slate-500">Note: {p.officer_note || 'N/A'}</span>
                </div>
                <span
                  className={`px-3 py-1 rounded-full text-xs font-bold uppercase ${
                    p.status === 'approved' ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'
                  }`}
                >
                  {p.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </main>

      {/* SANITIZE MODAL */}
      {editingPostForSanitize && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
              <Scissors className="w-5 h-5 text-indigo-600" />
              <div>
                <h3 className="font-bold text-base text-slate-900">কন্টাক্ট ইনফো স্যানিটাইজ ও অনুমোদন</h3>
                <span className="text-[11px] text-slate-500">অননুমোদিত ফোন/ইমেইল মুছে ফেলে পোস্টটি লাইভ করুন</span>
              </div>
            </div>

            <form onSubmit={handleSanitizeAndApprove} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-slate-700 uppercase mb-1">
                  সংশোধিত শিরোনাম (Cleaned Title) *
                </label>
                <input
                  type="text"
                  required
                  value={sanitizedTitle}
                  onChange={(e) => setSanitizedTitle(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-medium text-xs text-slate-900"
                />
                <span className="text-[11px] text-slate-400 mt-1 block">
                  মূল শিরোনাম: <span className="line-through text-rose-600">{editingPostForSanitize.title}</span>
                </span>
              </div>

              <div>
                <label className="block font-bold text-slate-700 uppercase mb-1">
                  কর্মকর্তার মন্তব্য (Officer Note)
                </label>
                <input
                  type="text"
                  value={officerNote}
                  onChange={(e) => setOfficerNote(e.target.value)}
                  placeholder="যেমন: ফোন নম্বর মুছে পোস্ট অনুমোদন করা হয়েছে"
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none text-xs"
                />
              </div>

              <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-900 text-[11px] leading-relaxed">
                ✅ স্যানিটাইজ করার পর পোস্টটি সরাসরি পাবলিক ফিডে প্রদর্শিত হবে। পোস্টারের মূল ফোন নম্বরটি শুধুমাত্র প্রাইভেট ডেটাবেসে থাকবে এবং ক্রেতা আনলক ফি পরিশোধ করলেই কেবল দেখতে পাবে।
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setEditingPostForSanitize(null)}
                  className="flex-1 py-2.5 bg-slate-100 text-slate-700 font-bold rounded-xl"
                >
                  বাতিল
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-sm"
                >
                  স্যানিটাইজ করে অনুমোদন দিন
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

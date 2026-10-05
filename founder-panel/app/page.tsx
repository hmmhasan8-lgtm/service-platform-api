'use client';

import React, { useState } from 'react';
import {
  Car,
  Wrench,
  UserCheck,
  Lock,
  LockOpen,
  MapPin,
  MessageSquare,
  Search,
  CheckCircle,
  Clock,
  Sparkles,
  Send,
  Globe,
  SlidersHorizontal,
  X,
  CreditCard,
  Zap,
  Star,
  ShieldCheck,
  Gift,
  Tag,
  Award,
} from 'lucide-react';
import { DynamicFormRenderer } from '../components/DynamicFormRenderer';
import { SingleWinnerSimulator } from '../components/SingleWinnerSimulator';
import { SeekerRequestFlow } from '../components/SeekerRequestFlow';
import { ProviderVerificationModal } from '../components/ProviderVerificationModal';
import { RatingModal } from '../components/RatingModal';
import { ReferralModal } from '../components/ReferralModal';
import { GenericColumnDefinition } from '../components/FieldBuilder';
import { DEFAULT_ENTITY_COLUMNS, EntityItem } from './founder/page';

interface UserClientPanelProps {
  entityColumnsState?: Record<string, GenericColumnDefinition[]>;
  entitiesList?: EntityItem[];
}

export default function UserClientPanel({ entityColumnsState, entitiesList }: UserClientPanelProps) {
  const [currentCountry, setCurrentCountry] = useState<'BD' | 'IN' | 'US'>('BD');
  const [searchQuery, setSearchQuery] = useState('');

  // 15 Columns definition per entity
  const columnsState = entityColumnsState || DEFAULT_ENTITY_COLUMNS;

  // Active Entities from Founder Panel
  const allEntities: EntityItem[] = entitiesList || [
    {
      id: 'e1',
      module_id: 'm1',
      module_key: 'vehicle_rental',
      entity_key: 'vehicles',
      name: { en: 'Rental Vehicles', bn: 'যানবাহন ভাড়া' },
      unlock_fee_usd: 1.0,
      validity_days: 7,
      is_active: true,
    },
    {
      id: 'e2',
      module_id: 'm2',
      module_key: 'service_marketplace',
      entity_key: 'services',
      name: { en: 'Home & Commercial Services', bn: 'পেশাদার সেবা' },
      unlock_fee_usd: 0.5,
      validity_days: 7,
      is_active: true,
    },
    {
      id: 'e3',
      module_id: 'm1',
      module_key: 'vehicle_rental',
      entity_key: 'drivers',
      name: { en: 'Verified Drivers', bn: 'ভেরিফায়েড ড্রাইভার' },
      unlock_fee_usd: 0.75,
      validity_days: 7,
      is_active: true,
    },
  ];

  const activeEntities = allEntities.filter((e) => e.is_active);

  const [activeEntityKey, setActiveEntityKey] = useState<string>(() => {
    return activeEntities[0]?.entity_key || 'vehicles';
  });

  const [activeView, setActiveView] = useState<'feed' | 'create_post' | 'seeker_request' | 'single_winner_sim' | 'chat'>('feed');

  // Modal visibility states
  const [showVerificationModal, setShowVerificationModal] = useState(false);
  const [showRatingModal, setShowRatingModal] = useState(false);
  const [showReferralModal, setShowReferralModal] = useState(false);
  const [isUserVerified, setIsUserVerified] = useState(false);
  const [couponCode, setCouponCode] = useState('');
  const [couponDiscount, setCouponDiscount] = useState<number>(0);
  const [couponMsg, setCouponMsg] = useState<string | null>(null);

  const selectedEntity = allEntities.find((e) => e.entity_key === activeEntityKey) || activeEntities[0];
  const active15Columns = columnsState[activeEntityKey] || DEFAULT_ENTITY_COLUMNS[activeEntityKey] || [];


  // Regional Configs
  const countryConfigs = {
    BD: { currency: '৳', multiplier: 120, gateway: 'bKash / Nagad', flag: '🇧🇩' },
    IN: { currency: '₹', multiplier: 85, gateway: 'Razorpay / UPI', flag: '🇮🇳' },
    US: { currency: '$', multiplier: 1, gateway: 'Stripe / Card', flag: '🇺🇸' },
  };

  const currentCfg = countryConfigs[currentCountry];

  // Feed Posts storing custom_col_1 through custom_col_15
  const [feedPosts, setFeedPosts] = useState([
    {
      id: 'post_1',
      title: 'Toyota Axio 2018 - Personal Used Condition',
      provider_name: 'তানভীর আহমেদ',
      entity_key: 'vehicles',
      country: 'BD',
      approx_location: 'উত্তরা সেক্টর ৭, ঢাকা',
      is_verified: true,
      avg_rating: 4.8,
      total_reviews: 120,
      level: 'Gold',
      // Generic Columns Data (15 Columns System)
      record_columns: {
        custom_col_1: 'CNG', // Fuel Type
        custom_col_2: '5000', // Security Deposit
        custom_col_3: '450', // Hourly Rate
        custom_col_4: '2018', // Model Year
        custom_col_5: '4', // Seating Capacity
        custom_col_6: '+8801711223344', // Owner Mobile (Private)
        custom_col_7: 'House 12, Road 4, Sector 7, Uttara, Dhaka', // Garage Location (Private)
      } as Record<string, any>,
      is_unlocked: false,
      unlock_price_usd: 1.0,
      unlock_valid_until: null as string | null,
    },
    {
      id: 'post_2',
      title: 'Noah Microbus - 8 Seats AC Tour Pack',
      provider_name: 'করিম এন্টারপ্রাইজ',
      entity_key: 'vehicles',
      country: 'BD',
      approx_location: 'মিরপুর ১০, ঢাকা',
      is_verified: true,
      avg_rating: 4.9,
      total_reviews: 85,
      level: 'Platinum',
      record_columns: {
        custom_col_1: 'Octane',
        custom_col_2: '8000',
        custom_col_3: '650',
        custom_col_4: '2019',
        custom_col_5: '8',
        custom_col_6: '+8801822998877',
        custom_col_7: 'Plot 44, Block C, Mirpur 10, Dhaka',
      } as Record<string, any>,
      is_unlocked: false,
      unlock_price_usd: 1.0,
      unlock_valid_until: null as string | null,
    },
  ]);

  // Payment Modal
  const [unlockingPost, setUnlockingPost] = useState<any | null>(null);
  const [paymentSuccessPopup, setPaymentSuccessPopup] = useState<string | null>(null);

  // Chat State
  const [activeChatPost, setActiveChatPost] = useState<any | null>(null);
  const [chatMessages, setChatMessages] = useState<Array<{ sender: 'buyer' | 'seller'; text: string; time: string }>>([
    { sender: 'buyer', text: 'আসসালামু আলাইকুম ভাই, গাড়ি কি কাল সকাল ৮টায় মিরপুর ১০ এ পাওয়া যাবে?', time: '11:02 AM' },
    { sender: 'seller', text: 'ওয়ালাইকুম আসসালাম। হ্যাঁ ভাই, একদম রেডি থাকবে।', time: '11:04 AM' },
  ]);
  const [newMessageText, setNewMessageText] = useState('');

  // Handle Unlock Payment
  const executePayment = (post: any) => {
    const validUntil = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toLocaleDateString('bn-BD');
    setFeedPosts((prev) =>
      prev.map((p) => {
        if (p.id === post.id) {
          return {
            ...p,
            is_unlocked: true,
            unlock_valid_until: validUntil,
          };
        }
        return p;
      })
    );
    setUnlockingPost(null);
    setPaymentSuccessPopup(
      `পেমেন্ট সফল! ৭ দিনের জন্য পোস্টের সকল গোপন তথ্য ও লাইভ চ্যাট আনলক হয়েছে।`
    );
    setTimeout(() => setPaymentSuccessPopup(null), 6000);
  };

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessageText.trim()) return;
    setChatMessages((prev) => [
      ...prev,
      { sender: 'buyer', text: newMessageText.trim(), time: 'Just now' },
    ]);
    setNewMessageText('');

    setTimeout(() => {
      setChatMessages((prev) => [
        ...prev,
        { sender: 'seller', text: 'জি ধন্যবাদ। যথাসময়ে যোগাযোগ হবে।', time: 'Just now' },
      ]);
    }, 1200);
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col font-sans">
      {/* App Bar */}
      <header className="sticky top-0 z-30 bg-white border-b border-slate-200 shadow-xs">
        <div className="max-w-6xl mx-auto px-4 py-3.5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-600 rounded-xl flex items-center justify-center text-white font-extrabold text-lg shadow-sm">
              S
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-lg text-slate-900 tracking-tight">SERVICE</span>
                <span className="text-[10px] px-2 py-0.5 bg-blue-50 text-blue-700 font-bold border border-blue-200 rounded-full">
                  15-Columns Architecture
                </span>
              </div>
              <p className="text-[11px] text-slate-500 hidden sm:block">Universal Commercial Communication Platform</p>
            </div>
          </div>

          {/* Regional Selector */}
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 bg-slate-100 p-1 rounded-xl border border-slate-200 text-xs">
              {(['BD', 'IN', 'US'] as const).map((code) => (
                <button
                  key={code}
                  onClick={() => setCurrentCountry(code)}
                  className={`px-2.5 py-1.5 rounded-lg font-bold transition flex items-center gap-1 ${
                    currentCountry === code
                      ? 'bg-white text-blue-600 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <span>{countryConfigs[code].flag}</span>
                  <span>{code}</span>
                </button>
              ))}
            </div>

            {/* MODULE 1: NID Verification Trigger */}
            <button
              onClick={() => setShowVerificationModal(true)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 shadow-xs ${
                isUserVerified
                  ? 'bg-emerald-50 text-emerald-800 border border-emerald-300'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200 border border-slate-200'
              }`}
            >
              <ShieldCheck className={`w-3.5 h-3.5 ${isUserVerified ? 'text-emerald-600' : 'text-slate-500'}`} />
              <span>{isUserVerified ? 'NID ভেরিফায়েড ✅' : 'NID Verify করুন'}</span>
            </button>

            {/* MODULE 3: Refer & Earn Trigger */}
            <button
              onClick={() => setShowReferralModal(true)}
              className="px-3 py-1.5 rounded-xl text-xs font-bold bg-rose-50 text-rose-700 hover:bg-rose-100 border border-rose-200 transition flex items-center gap-1.5 shadow-xs"
            >
              <Gift className="w-3.5 h-3.5 text-rose-600" />
              <span>রেফার ও আয় (৳১০০)</span>
            </button>
 
            <button
              onClick={() => setActiveView(activeView === 'single_winner_sim' ? 'feed' : 'single_winner_sim')}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1.5 shadow-xs ${
                activeView === 'single_winner_sim'
                  ? 'bg-amber-500 text-slate-950 font-extrabold'
                  : 'bg-amber-50 text-amber-900 border border-amber-300 hover:bg-amber-100'
              }`}
            >
              <Zap className="w-3.5 h-3.5 fill-current" />
              <span>একক বিজয়ী সিমুলেটর</span>
            </button>

            <button
              onClick={() => setActiveView(activeView === 'create_post' ? 'feed' : 'create_post')}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-xs transition"
            >
              {activeView === 'create_post' ? 'পোস্ট ফিড দেখুন' : '+ পোস্ট করুন'}
            </button>
          </div>
        </div>

        {/* Entity Navigation */}
        <div className="max-w-6xl mx-auto px-4 flex gap-4 border-t border-slate-100 overflow-x-auto">
          {activeEntities.map((tab) => {
            const isSelected = activeEntityKey === tab.entity_key;
            return (
              <button
                key={tab.entity_key}
                onClick={() => {
                  setActiveEntityKey(tab.entity_key);
                  setActiveView('feed');
                }}
                className={`py-3 px-2 text-xs font-bold flex items-center gap-2 border-b-2 transition whitespace-nowrap ${
                  isSelected ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-900'
                }`}
              >
                <span>{tab.name.bn}</span>
                <span className="text-[10px] font-mono opacity-60">({tab.entity_key})</span>
              </button>
            );
          })}
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 max-w-6xl mx-auto w-full p-4 sm:p-6">
        {paymentSuccessPopup && (
          <div className="mb-6 p-4 bg-emerald-500 text-white rounded-2xl shadow-lg flex items-center justify-between">
            <div className="flex items-center gap-3">
              <CheckCircle className="w-6 h-6 flex-shrink-0" />
              <span className="text-sm font-semibold">{paymentSuccessPopup}</span>
            </div>
            <button onClick={() => setPaymentSuccessPopup(null)} className="p-1 hover:bg-emerald-600 rounded">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* VIEW 0: SINGLE-WINNER RACE CONDITION SIMULATOR */}
        {activeView === 'single_winner_sim' && (
          <SingleWinnerSimulator />
        )}

        {/* VIEW 1: FEED */}
        {activeView === 'feed' && (
          <div className="space-y-6">
            {/* MODULE 4 B: 2 BIG CARDS (USER PANEL 2 BUTTONS) */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* CARD 1: পোস্ট করুন (Provider Post) */}
              <button
                onClick={() => setActiveView('create_post')}
                className="p-5 bg-gradient-to-br from-blue-600 to-indigo-700 hover:from-blue-700 hover:to-indigo-800 text-white rounded-3xl shadow-sm hover:shadow-md transition text-left flex items-start gap-4 group"
              >
                <div className="p-3.5 bg-white/20 rounded-2xl text-2xl group-hover:scale-110 transition-transform flex-shrink-0">
                  📝
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-extrabold text-base">পোস্ট করুন</h3>
                    <span className="px-2 py-0.5 rounded-full bg-white/20 text-[10px] font-bold">সার্ভিস প্রদানকারী</span>
                  </div>
                  <p className="text-xs text-blue-100 mt-1 leading-relaxed">
                    আপনি কি সার্ভিস দেন? আপনার সার্ভিসের বিজ্ঞাপন দিন ও সরাসরি গ্রাহক পান
                  </p>
                </div>
              </button>

              {/* CARD 2: আবেদন করুন (Seeker Request) */}
              <button
                onClick={() => setActiveView('seeker_request')}
                className="p-5 bg-gradient-to-br from-emerald-600 to-teal-700 hover:from-emerald-700 hover:to-teal-800 text-white rounded-3xl shadow-sm hover:shadow-md transition text-left flex items-start gap-4 group"
              >
                <div className="p-3.5 bg-white/20 rounded-2xl text-2xl group-hover:scale-110 transition-transform flex-shrink-0">
                  🙋
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-extrabold text-base">আবেদন করুন</h3>
                    <span className="px-2 py-0.5 rounded-full bg-amber-400 text-slate-950 text-[10px] font-extrabold">কাছাকাছি প্রোভাইডার</span>
                  </div>
                  <p className="text-xs text-emerald-100 mt-1 leading-relaxed">
                    আপনার সার্ভিস লাগবে? কাছাকাছি ভেরিফায়েড প্রোভাইডারদের কাছে রিকোয়েস্ট পাঠান
                  </p>
                </div>
              </button>
            </div>

            {/* Search Bar */}
            <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between gap-3">
              <div className="flex items-center gap-2 flex-1">
                <Search className="w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="কী খুঁজছেন? যেমন: Axio, Noah..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full text-xs text-slate-800 placeholder-slate-400 outline-none"
                />
              </div>
              <span className="text-xs font-semibold text-slate-500">
                {active15Columns.filter((c) => c.is_active).length} Active Fields Configured
              </span>
            </div>

            {/* Post Cards Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {feedPosts.map((post) => {
                const unlockFeeLocal = (post.unlock_price_usd * currentCfg.multiplier).toFixed(0);

                // Get Active Public and Private Columns for this post
                const activePublicCols = active15Columns.filter((col) => col.is_active && !col.is_private);
                const activePrivateCols = active15Columns.filter((col) => col.is_active && col.is_private);

                return (
                  <div
                    key={post.id}
                    className="bg-white rounded-2xl border border-slate-200 shadow-xs hover:shadow-md transition p-5 flex flex-col justify-between"
                  >
                    <div>
                      {/* Header Tag */}
                      <div className="flex items-center justify-between mb-2">
                        <span className="px-2.5 py-1 bg-blue-50 text-blue-700 text-[11px] font-bold rounded-md">
                          {selectedEntity?.name.bn || activeEntityKey}
                        </span>
                        <span className="text-xs text-slate-400 flex items-center gap-1 font-medium">
                          <MapPin className="w-3.5 h-3.5 text-slate-400" />
                          {post.approx_location}
                        </span>
                      </div>

                      <h3 className="text-base font-bold text-slate-900 leading-snug">{post.title}</h3>

                      {/* MODULE 1 & 2: Provider Info with Verification Badge & Rating/Level */}
                      <div className="flex flex-wrap items-center justify-between gap-2 mt-2 pt-2 border-t border-slate-100 text-xs">
                        <div className="flex items-center gap-1.5">
                          <span className="font-bold text-slate-800">{post.provider_name}</span>
                          {post.is_verified && (
                            <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 bg-emerald-50 text-emerald-700 border border-emerald-300 rounded text-[10px] font-extrabold" title="NID ভেরিফায়েড">
                              <ShieldCheck className="w-3 h-3 text-emerald-600" />
                              <span>ভেরিফায়েড</span>
                            </span>
                          )}
                        </div>
                        <span className="text-[11px] font-semibold text-amber-700 flex items-center gap-1 bg-amber-50 px-2 py-0.5 rounded-lg border border-amber-200">
                          <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
                          <span>{post.avg_rating} ({post.total_reviews}) • {post.level} Level</span>
                        </span>
                      </div>

                      {/* RENDER ACTIVE PUBLIC COLUMNS DYNAMICALLY (custom_col_1 .. custom_col_15) */}
                      <div className="mt-3 grid grid-cols-2 sm:grid-cols-3 gap-2 bg-slate-50 p-3 rounded-xl border border-slate-100 text-xs">
                        {activePublicCols.slice(0, 6).map((col) => {
                          const val = post.record_columns[col.col_key] || '—';
                          const label = col.label_bn || col.label_en;
                          return (
                            <div key={col.col_key}>
                              <span className="text-slate-400 block text-[10px] uppercase font-bold truncate">
                                {label}
                              </span>
                              <span className="font-bold text-slate-800 truncate block">
                                {col.data_type === 'currency' ? `${currentCfg.currency} ${val}` : val}
                              </span>
                            </div>
                          );
                        })}
                      </div>

                      {/* SENSITIVE / UNLOCK SECTION (PRIVATE COLUMNS) */}
                      <div className="mt-4 pt-3 border-t border-slate-100">
                        {post.is_unlocked ? (
                          <div className="p-3.5 bg-emerald-50 border border-emerald-200 rounded-xl space-y-1.5">
                            <div className="flex items-center justify-between text-xs text-emerald-800 font-bold">
                              <span className="flex items-center gap-1.5">
                                <LockOpen className="w-4 h-4 text-emerald-600" /> আনলক করা তথ্য (৭ দিনের মেয়াদ)
                              </span>
                              <span className="text-[10px] bg-emerald-100 px-2 py-0.5 rounded text-emerald-900">
                                Valid: {post.unlock_valid_until}
                              </span>
                            </div>
                            <div className="text-xs text-slate-800 pt-1 space-y-1">
                              {activePrivateCols.map((col) => {
                                const val = post.record_columns[col.col_key] || 'তথ্য বিদ্যমান';
                                const label = col.label_bn || col.label_en;
                                return (
                                  <div key={col.col_key}>
                                    <span className="font-bold text-slate-600">{label}: </span>
                                    <span className="font-mono text-emerald-700 font-bold">{val}</span>
                                  </div>
                                );
                              })}
                            </div>
                          </div>
                        ) : (
                          <div className="p-3.5 bg-amber-50/70 border border-amber-200 rounded-xl space-y-1">
                            {activePrivateCols.map((col) => {
                              const label = col.label_bn || col.label_en;
                              return (
                                <div key={col.col_key} className="flex items-center gap-2">
                                  <Lock className="w-3.5 h-3.5 text-amber-700 flex-shrink-0" />
                                  <div className="text-xs text-amber-900">
                                    <span className="font-bold">{label}: </span>
                                    <span className="font-mono font-normal text-amber-700">*** Unlock Required ***</span>
                                  </div>
                                </div>
                              );
                            })}
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Action Button */}
                    <div className="mt-4 pt-2">
                      {post.is_unlocked ? (
                        <button
                          onClick={() => {
                            setActiveChatPost(post);
                            setActiveView('chat');
                          }}
                          className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 shadow-xs transition"
                        >
                          <MessageSquare className="w-4 h-4" />
                          সরাসরি চ্যাট করুন (Live WebSocket)
                        </button>
                      ) : (
                        <button
                          onClick={() => setUnlockingPost(post)}
                          className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 shadow-xs transition"
                        >
                          <Lock className="w-4 h-4" />
                          যোগাযোগ ও গোপন তথ্য আনলক করুন ({currentCfg.currency} {unlockFeeLocal})
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* VIEW 2: DYNAMIC FORM CREATE POST */}
        {activeView === 'create_post' && (
          <div>
            <DynamicFormRenderer
              entityKey={activeEntityKey}
              entityName={selectedEntity?.name.bn || activeEntityKey}
              columns={active15Columns}
              language="bn"
              countryCode={currentCountry}
              currencySymbol={currentCfg.currency}
              onSubmit={async (formData) => {
                const newPost = {
                  id: 'post_' + Date.now(),
                  title: formData.title,
                  provider_name: 'নতুন প্রোভাইডার',
                  entity_key: activeEntityKey,
                  country: currentCountry,
                  approx_location: formData.approx_location,
                  is_verified: isUserVerified,
                  avg_rating: 5.0,
                  total_reviews: 1,
                  level: 'New',
                  record_columns: formData.recordValues,
                  is_unlocked: false,
                  unlock_price_usd: selectedEntity?.unlock_fee_usd || 1.0,
                  unlock_valid_until: null,
                };
                setFeedPosts([newPost, ...feedPosts]);
                setActiveView('feed');
              }}
            />
          </div>
        )}

        {/* VIEW 2.5: SEEKER REQUEST FLOW (MODULE 4 B: আবেদন করুন) */}
        {activeView === 'seeker_request' && (
          <SeekerRequestFlow
            onCancel={() => setActiveView('feed')}
            onSuccess={(reqData) => {
              setActiveView('feed');
              setPaymentSuccessPopup('আপনার রিকোয়েস্ট সফলভাবে কাছাকাছি ভেরিফায়েড প্রোভাইডারদের কাছে পাঠানো হয়েছে!');
            }}
            currencySymbol={currentCfg.currency}
            countryCode={currentCountry}
          />
        )}

        {/* VIEW 3: LIVE POST-UNLOCK CHAT */}
        {activeView === 'chat' && activeChatPost && (
          <div className="max-w-2xl mx-auto bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden flex flex-col h-[520px]">
            {/* Chat Header */}
            <div className="bg-slate-900 text-white p-4 flex items-center justify-between">
              <div>
                <h4 className="font-bold text-sm">{activeChatPost.title}</h4>
                <div className="flex items-center gap-2 text-xs text-slate-300">
                  <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
                  <span>{activeChatPost.provider_name} • ৭ দিনের মেয়াদ সক্রিয়</span>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {/* MODULE 2: "কাজ শেষ হয়েছে?" Rating Trigger */}
                <button
                  onClick={() => setShowRatingModal(true)}
                  className="px-3 py-1.5 bg-amber-500 hover:bg-amber-600 text-slate-950 font-extrabold text-xs rounded-lg flex items-center gap-1 shadow-sm transition"
                >
                  <Star className="w-3.5 h-3.5 fill-current" />
                  <span>কাজ শেষ হয়েছে?</span>
                </button>
                <button
                  onClick={() => setActiveView('feed')}
                  className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-xs rounded-lg font-bold"
                >
                  বন্ধ করুন
                </button>
              </div>
            </div>

            {/* Chat Body */}
            <div className="flex-1 p-4 overflow-y-auto space-y-3 bg-slate-50">
              {chatMessages.map((msg, i) => (
                <div key={i} className={`flex ${msg.sender === 'buyer' ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`max-w-[80%] p-3 rounded-2xl text-xs ${
                      msg.sender === 'buyer'
                        ? 'bg-blue-600 text-white rounded-br-none'
                        : 'bg-white text-slate-800 border border-slate-200 rounded-bl-none shadow-xs'
                    }`}
                  >
                    <p>{msg.text}</p>
                    <span
                      className={`text-[9px] block text-right mt-1 ${
                        msg.sender === 'buyer' ? 'text-blue-200' : 'text-slate-400'
                      }`}
                    >
                      {msg.time}
                    </span>
                  </div>
                </div>
              ))}
            </div>

            {/* Chat Input */}
            <form onSubmit={handleSendMessage} className="p-3 bg-white border-t border-slate-200 flex gap-2">
              <input
                type="text"
                value={newMessageText}
                onChange={(e) => setNewMessageText(e.target.value)}
                placeholder="মেসেজ লিখুন..."
                className="flex-1 px-3.5 py-2.5 text-xs bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
              />
              <button type="submit" className="p-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl">
                <Send className="w-4 h-4" />
              </button>
            </form>
          </div>
        )}
      </main>

      {/* UNLOCK MODAL WITH COUPON SUPPORT (MODULE 3) */}
      {unlockingPost && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-blue-50 text-blue-600 rounded-xl">
                <CreditCard className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-bold text-base text-slate-900">গোপন তথ্য আনলক ফি</h3>
                <p className="text-xs text-slate-500">৭ দিনের জন্য সরাসরি কল ও চ্যাট</p>
              </div>
            </div>

            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 text-xs space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-500">পোস্ট:</span>
                <span className="font-bold text-slate-800 text-right truncate max-w-[180px]">
                  {unlockingPost.title}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">গেটওয়ে:</span>
                <span className="font-bold text-slate-800">{currentCfg.gateway}</span>
              </div>

              {/* MODULE 3: Coupon Code Input */}
              <div className="pt-2 border-t border-slate-200">
                <label className="block text-[10px] font-bold text-slate-600 uppercase mb-1">
                  কুপন কোড (Coupon Code)
                </label>
                <div className="flex gap-1.5">
                  <input
                    type="text"
                    placeholder="যেমন: EID50"
                    value={couponCode}
                    onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                    className="flex-1 px-2.5 py-1.5 text-xs bg-white border border-slate-300 rounded-lg font-mono outline-none uppercase"
                  />
                  <button
                    type="button"
                    onClick={() => {
                      if (couponCode.trim().toUpperCase() === 'EID50') {
                        setCouponDiscount(50);
                        setCouponMsg('🎉 ৫০% ছাড় সক্রিয়!');
                      } else {
                        setCouponDiscount(0);
                        setCouponMsg('❌ কুপন কোড সঠিক নয়');
                      }
                    }}
                    className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-lg text-xs"
                  >
                    Apply
                  </button>
                </div>
                {couponMsg && (
                  <p className={`text-[10px] font-bold mt-1 ${couponDiscount > 0 ? 'text-emerald-600' : 'text-rose-500'}`}>
                    {couponMsg}
                  </p>
                )}
              </div>

              <div className="flex justify-between border-t border-slate-200 pt-2 text-sm">
                <span className="font-bold text-slate-700">মোট পরিশোধযোগ্য:</span>
                <div className="text-right">
                  {couponDiscount > 0 && (
                    <span className="line-through text-xs text-slate-400 mr-1.5">
                      {currentCfg.currency} {(unlockingPost.unlock_price_usd * currentCfg.multiplier).toFixed(0)}
                    </span>
                  )}
                  <span className="font-extrabold text-emerald-600">
                    {currentCfg.currency} {((unlockingPost.unlock_price_usd * currentCfg.multiplier) * (1 - couponDiscount / 100)).toFixed(0)}
                  </span>
                </div>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => {
                  setUnlockingPost(null);
                  setCouponCode('');
                  setCouponDiscount(0);
                  setCouponMsg(null);
                }}
                className="flex-1 py-2.5 bg-slate-100 text-slate-700 rounded-xl font-bold text-xs"
              >
                বাতিল
              </button>
              <button
                onClick={() => {
                  executePayment(unlockingPost);
                  setCouponCode('');
                  setCouponDiscount(0);
                  setCouponMsg(null);
                }}
                className="flex-1 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold text-xs shadow-md transition"
              >
                পেমেন্ট করুন ({currentCfg.gateway.split(' ')[0]})
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODULE 1: NID + FACE VERIFICATION MODAL */}
      <ProviderVerificationModal
        isOpen={showVerificationModal}
        onClose={() => setShowVerificationModal(false)}
        userId="usr_demo_101"
        userName="তানভীর আহমেদ"
        isVerified={isUserVerified}
        onVerifiedSuccess={() => {
          setIsUserVerified(true);
          setShowVerificationModal(false);
          setPaymentSuccessPopup('অভিনন্দন! আপনার NID ভেরিফিকেশন সফলভাবে অনুমোদিত হয়েছে!');
        }}
      />

      {/* MODULE 2: RATING & GAMIFICATION MODAL */}
      <RatingModal
        isOpen={showRatingModal}
        onClose={() => setShowRatingModal(false)}
        requestId="req_101"
        providerName={activeChatPost?.provider_name || 'সার্ভিস প্রোভাইডার'}
        providerId="prov_101"
        currentLevel={activeChatPost?.level || 'Gold'}
        onRatingSuccess={(stars, review) => {
          setPaymentSuccessPopup(`ধন্যবাদ! আপনি ${stars} স্টার রেটিং প্রদান করেছেন।`);
        }}
      />

      {/* MODULE 3: REFERRAL MODAL */}
      <ReferralModal
        isOpen={showReferralModal}
        onClose={() => setShowReferralModal(false)}
        userId="usr_demo_101"
        userReferralCode="ARIF123"
      />
    </div>
  );
}

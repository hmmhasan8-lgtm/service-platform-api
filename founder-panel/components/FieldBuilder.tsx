import React, { useState } from 'react';
import { Lock, Save, Sparkles, Check, Globe, Eye, EyeOff } from 'lucide-react';

export interface GenericColumnDefinition {
  col_key: string; // "custom_col_1" ... "custom_col_15"
  label_en: string;
  label_bn: string;
  data_type: 'text' | 'currency' | 'select' | 'phone' | 'geo_point' | 'number';
  is_private: boolean;
  is_active: boolean;
  is_required?: boolean;
  options?: string[]; // e.g. ["CNG", "Petrol", "Octane"]
  target_countries?: string[]; // ["*"], ["BD"], etc.
}

interface FieldBuilderProps {
  entityKey: string;
  entityName: string;
  initialColumns: GenericColumnDefinition[];
  onSaveColumns: (updatedColumns: GenericColumnDefinition[]) => void;
}

export const FieldBuilder: React.FC<FieldBuilderProps> = ({
  entityKey,
  entityName,
  initialColumns,
  onSaveColumns,
}) => {
  const [columns, setColumns] = useState<GenericColumnDefinition[]>(() => {
    // Ensure all 15 columns exist
    const map = new Map(initialColumns.map((c) => [c.col_key, c]));
    const full15: GenericColumnDefinition[] = [];
    for (let i = 1; i <= 15; i++) {
      const key = `custom_col_${i}`;
      if (map.has(key)) {
        full15.push({ ...map.get(key)! });
      } else {
        full15.push({
          col_key: key,
          label_en: `Custom Field ${i}`,
          label_bn: `কাস্টম ফিল্ড ${i}`,
          data_type: 'text',
          is_private: false,
          is_active: false,
          is_required: false,
          options: [],
          target_countries: ['*'],
        });
      }
    }
    return full15;
  });

  const [savedSuccess, setSavedSuccess] = useState(false);

  const updateColumn = (index: number, updates: Partial<GenericColumnDefinition>) => {
    setColumns((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], ...updates };
      return next;
    });
  };

  const handleSave = () => {
    onSaveColumns(columns);
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 4000);
  };

  const activeCount = columns.filter((c) => c.is_active).length;

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4 pb-4 border-b border-slate-100">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-indigo-600" />
              15 Generic Columns Renaming Desk
            </h3>
            <span className="px-2.5 py-0.5 bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-bold rounded-full">
              Entity: {entityKey}
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            টেবিলে আগে থেকেই ১৫টি কলাম তৈরি করা আছে। ফাউন্ডার শুধু নাম পরিবর্তন এবং অন/অফ (Active Switch) করবেন—কোনো কোড বা মাইগ্রেশন লাগবে না।
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="text-xs font-semibold px-3 py-1.5 bg-slate-100 rounded-lg text-slate-700">
            Active Columns: <span className="font-bold text-indigo-600">{activeCount} / 15</span>
          </div>
          <button
            onClick={handleSave}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm transition"
          >
            <Save className="w-4 h-4" /> Save 15 Columns Config
          </button>
        </div>
      </div>

      {savedSuccess && (
        <div className="p-3 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl text-xs font-bold flex items-center gap-2">
          <Check className="w-4 h-4 text-emerald-600" />
          ১৫টি কলামের কনফিগারেশন সফলভাবে আপডেট হয়েছে! অ্যাপে সাথে সাথে নতুন লেবেল কার্যকর হয়েছে।
        </div>
      )}

      {/* 15 ROWS TABLE */}
      <div className="overflow-x-auto border border-slate-200 rounded-xl">
        <table className="w-full text-left text-xs">
          <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase tracking-wider">
            <tr>
              <th className="p-3.5 w-16">Active?</th>
              <th className="p-3.5 w-32">DB Column</th>
              <th className="p-3.5 min-w-[150px]">Label (English)</th>
              <th className="p-3.5 min-w-[150px]">Label (বাংলা)</th>
              <th className="p-3.5 w-36">Data Type</th>
              <th className="p-3.5 min-w-[180px]">Options (if Select)</th>
              <th className="p-3.5 w-24 text-center">Private (🔒)</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {columns.map((col, idx) => {
              return (
                <tr
                  key={col.col_key}
                  className={`transition ${
                    col.is_active ? 'bg-white hover:bg-slate-50/80' : 'bg-slate-50/50 text-slate-400'
                  }`}
                >
                  {/* ACTIVE SWITCH */}
                  <td className="p-3.5 text-center">
                    <button
                      type="button"
                      onClick={() => updateColumn(idx, { is_active: !col.is_active })}
                      className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none ${
                        col.is_active ? 'bg-emerald-600' : 'bg-slate-300'
                      }`}
                      title={col.is_active ? 'Active (Shown to users)' : 'Inactive (Hidden)'}
                    >
                      <span
                        className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white transition-transform ${
                          col.is_active ? 'translate-x-4' : 'translate-x-1'
                        }`}
                      />
                    </button>
                  </td>

                  {/* COLUMN KEY (READONLY) */}
                  <td className="p-3.5 font-mono font-bold text-slate-700 whitespace-nowrap">
                    <span className={`px-2 py-1 rounded text-[11px] ${col.is_active ? 'bg-slate-100' : 'bg-slate-200/60 text-slate-400'}`}>
                      {col.col_key}
                    </span>
                  </td>

                  {/* LABEL EN INPUT */}
                  <td className="p-3.5">
                    <input
                      type="text"
                      disabled={!col.is_active}
                      value={col.label_en}
                      onChange={(e) => updateColumn(idx, { label_en: e.target.value })}
                      placeholder="e.g. Category"
                      className={`w-full px-2.5 py-1.5 border rounded-lg outline-none text-xs ${
                        col.is_active
                          ? 'bg-white border-slate-300 text-slate-900 focus:border-indigo-500 font-medium'
                          : 'bg-slate-100 border-slate-200 text-slate-400'
                      }`}
                    />
                  </td>

                  {/* LABEL BN INPUT */}
                  <td className="p-3.5">
                    <input
                      type="text"
                      disabled={!col.is_active}
                      value={col.label_bn}
                      onChange={(e) => updateColumn(idx, { label_bn: e.target.value })}
                      placeholder="যেমন: ক্যাটাগরি"
                      className={`w-full px-2.5 py-1.5 border rounded-lg outline-none text-xs font-bengali ${
                        col.is_active
                          ? 'bg-white border-slate-300 text-slate-900 focus:border-indigo-500 font-medium'
                          : 'bg-slate-100 border-slate-200 text-slate-400'
                      }`}
                    />
                  </td>

                  {/* DATA TYPE */}
                  <td className="p-3.5">
                    <select
                      disabled={!col.is_active}
                      value={col.data_type}
                      onChange={(e) => updateColumn(idx, { data_type: e.target.value as any })}
                      className={`w-full px-2 py-1.5 border rounded-lg outline-none text-xs ${
                        col.is_active
                          ? 'bg-white border-slate-300 text-slate-800'
                          : 'bg-slate-100 border-slate-200 text-slate-400'
                      }`}
                    >
                      <option value="text">text (Text)</option>
                      <option value="currency">currency (৳, $, ₹)</option>
                      <option value="select">select (Dropdown)</option>
                      <option value="phone">phone (Mobile)</option>
                      <option value="geo_point">geo_point (Location)</option>
                      <option value="number">number (Integer)</option>
                    </select>
                  </td>

                  {/* OPTIONS (FOR SELECT) */}
                  <td className="p-3.5">
                    {col.data_type === 'select' ? (
                      <input
                        type="text"
                        disabled={!col.is_active}
                        value={(col.options || []).join(', ')}
                        onChange={(e) =>
                          updateColumn(idx, {
                            options: e.target.value.split(',').map((s) => s.trim()).filter(Boolean),
                          })
                        }
                        placeholder="AC, Plumbing, Electric"
                        className="w-full px-2.5 py-1.5 border border-slate-300 rounded-lg outline-none text-xs bg-white focus:border-indigo-500"
                      />
                    ) : (
                      <span className="text-slate-300 text-[11px] italic">—</span>
                    )}
                  </td>

                  {/* PRIVATE SWITCH (🔒) */}
                  <td className="p-3.5 text-center">
                    <button
                      type="button"
                      disabled={!col.is_active}
                      onClick={() => updateColumn(idx, { is_private: !col.is_private })}
                      className={`p-1.5 rounded-lg border transition ${
                        !col.is_active
                          ? 'opacity-40 cursor-not-allowed border-slate-200'
                          : col.is_private
                          ? 'bg-amber-100 border-amber-300 text-amber-800 font-bold shadow-xs'
                          : 'bg-slate-100 border-slate-200 text-slate-400 hover:text-slate-700'
                      }`}
                      title={
                        col.is_private
                          ? '🔒 Private (Locked until user pays unlock fee)'
                          : 'Publicly visible'
                      }
                    >
                      <Lock className="w-3.5 h-3.5" />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between pt-2">
        <p className="text-xs text-slate-500">
          💡 টিপস: আপনি যখন কোনো কলামের নাম পরিবর্তন করে <strong>Active</strong> করবেন, সাথে সাথে ইউজার প্যানেলের পোস্ট ফর্মে সেই ফিল্ডটি চলে আসবে।
        </p>
        <button
          onClick={handleSave}
          className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-sm transition"
        >
          <Save className="w-4 h-4" /> Save Configuration
        </button>
      </div>
    </div>
  );
};

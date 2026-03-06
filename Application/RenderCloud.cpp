// Copyright Epic Games, Inc. All Rights Reserved.


#include "Game.h"

#include "windows.h"

#include <imgui.h>

void Game::renderCloud()
{
	D3dRenderContext* context = g_dx11Device->getDeviceContext();
	GPU_SCOPED_TIMEREVENT(Cloud, 76, 34, 177);

	if (!RenderCloud)
		return;

	const D3dViewport& backBufferViewport = g_dx11Device->getBackBufferViewport();
	D3dRenderTargetView* backBuffer = g_dx11Device->getBackBufferRT();

	mConstantBufferCPU.gViewProjMat = mViewProjMat;
	mConstantBufferCPU.gResolution[0] = uint32(backBufferViewport.Width);
	mConstantBufferCPU.gResolution[1] = uint32(backBufferViewport.Height);
	mConstantBuffer->update(mConstantBufferCPU);

	context->RSSetViewports(1, &backBufferViewport);

	{
		context->OMSetRenderTargetsAndUnorderedAccessViews(1, &mBackBufferHdr->mRenderTargetView, mBackBufferDepth->mDepthStencilView, 0, 0, nullptr, nullptr);
		context->OMSetDepthStencilState(mDisabledDepthStencilState->mState, 0);
		context->OMSetBlendState(BlendPreMutlAlpha->mState, nullptr, 0xffffffff);

		// Set null input assembly and layout
		context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
		context->IASetInputLayout(nullptr);

		// Final view
		mCloudVertexShader->setShader(*context);
		mCloudPixelShader->setShader(*context);

		context->VSSetConstantBuffers(0, 1, &mConstantBuffer->mBuffer);
		context->VSSetConstantBuffers(1, 1, &SkyAtmosphereBuffer->mBuffer);

		// Draw cube (36 vertices for 12 triangles)
		// context->Draw(36, 0);
		context->DrawInstanced(36, 1, 0, 0);
		g_dx11Device->setNullPsResources(context);
		g_dx11Device->setNullRenderTarget(context);
		context->OMSetBlendState(mDefaultBlendState->mState, nullptr, 0xffffffff);
	}
}
